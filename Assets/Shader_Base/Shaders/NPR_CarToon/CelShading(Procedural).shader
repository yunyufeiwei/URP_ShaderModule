Shader "Art_URP/Base/NPR/CelShading-Procedural"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _BackColor ("Back Color", Color) = (1,1,1,1)
        _BackRange ("Back Range", Range(0,1)) = 0.5
        _DiffuseRampSmoothness ("Diffuse Ramp Smoothness", Range(0,1)) = 0.5
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _SpecularRange ("Specular Range", Range(0,1)) = 0.5
        _SpecularRampSmoothness ("Specular Ramp Smoothness", Range(0,1)) = 0.5
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
                float3 normalWS   : TEXCOORD0;
                float3 viewWS       : TEXCOORD1;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _BackColor;
                float  _BackRange;
                float  _DiffuseRampSmoothness;
                float4 _SpecularColor;
                float  _SpecularRange;
                float  _SpecularRampSmoothness;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.viewWS = GetWorldSpaceViewDir(positionWS);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;
                Light light = GetMainLight();
                half3 lightColor = light.color * light.distanceAttenuation;
                half3 lightDir = light.direction;

                half3 ambientColor = unity_AmbientSky.rgb;

                half3 worldNormalDir = normalize(i.normalWS);
                half3 worldViewDir = normalize(i.viewWS);

                half halfLambert = saturate(dot(worldNormalDir,lightDir)) * 0.5 + 0.5;
                //使用step也可以替代，step效果会是卡硬的二分表现
                half diffuseRamp = smoothstep(0,max(_DiffuseRampSmoothness , 0.005) , halfLambert - _BackRange);
                // half diffuseRamp = step(_DiffuseRampSmoothness , halfLambert - _BackRange);

                half3 mainColor = lightColor * _BaseColor;
                half3 diffuseColor =  lerp(_BackColor , mainColor , diffuseRamp) ;

                //SPECULAR
                half3 halfDir = normalize(lightDir+worldViewDir);
                half NdotH = saturate(dot(worldNormalDir,halfDir));

                half w = fwidth(NdotH) * 2 + _SpecularRampSmoothness;
                half specularRamp = smoothstep(0,w, NdotH + _SpecularRange - 1);
                specularRamp *= diffuseRamp;

                half3 specularColor =lightColor * _SpecularColor * specularRamp ;

                FinalColor = half4(ambientColor + diffuseColor + specularColor ,1);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
