Shader "Art_URP/Base/Light/Wrap"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _Wrap("Wrap",Range(0,1)) = 0
        _FixColor("FixColor" ,Color) = (1,1,1,1)
        _FixWidth("FixWidth" , Range(0,0.5)) = 0
        _SpecularColor("SpecularColor",Color) = (1,1,1,1)
        _SpecularGloss("SpecularGloss" , Range(8,255)) = 20
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}

        LOD 100

        pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS     : POSITION;
                float3 normalOS       : NORMAL;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 positionWS   : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
            };
            
            CBUFFER_START(UnityPerMaterial)
            float4 _Color;
            float _Wrap;
            float4 _FixColor;
            float _FixWidth;
            float4 _SpecularColor;
            float _SpecularGloss;
            CBUFFER_END

            //WrapLighting直译就是用光包裹住整个物体，让原来黑暗(N*L<0)的部分亮起来的意思。而WrapLighting会有一个光的过度，并且soft整个物体。
            half3 WrapLighting(half3 LightDir , half3 noramlDir , half wrap)
            {
                half diffuse = max(0, dot(noramlDir,LightDir));
                float wrap_diffuse = max(0 , (dot(noramlDir,LightDir) + wrap) / (1 + wrap));
                return wrap_diffuse;
            }

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;
                Light light = GetMainLight();
                half3 worldLightDir = light.direction;
                half3 worldNomralDir = normalize(i.normalWS);
                half3 worldViewDir  = GetWorldSpaceNormalizeViewDir(i.positionWS);

                half3 warpDiffuse = WrapLighting(worldLightDir,worldNomralDir,_Wrap);

                half3 diffuseColor = light.color * _Color.rgb * saturate(warpDiffuse);
                half3 fixColor = light.color * _FixColor.rgb * smoothstep(0,_FixWidth , warpDiffuse) * smoothstep(_FixWidth * 2 , _FixWidth , warpDiffuse);

                half3 halfDir = normalize(worldViewDir + worldLightDir);
                half3 specular = light.color * _SpecularColor.rgb * pow(saturate(dot(worldNomralDir , halfDir)) , _SpecularGloss);

                FinalColor = half4(diffuseColor + fixColor + specular,1);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
