//把经典光照模型中的N·H，改成N·V，这个高光形状就会非常接近于卡通的清漆光的形状
//很适合用来处理一些皮革，圆柱形的金属等

//参考资料：
//https://developer.unity.cn/projects/618ce1e7edbc2a05bb615020

Shader "Art_URP/Base/NPR/StylizedHighClearCoat"
{
    Properties
    {
        _SpecularColor ("SpecularGloss", Color) = (1,1,1,1)
        _Smoothness ("Smoothness", Range(8,255)) = 20
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
                float4 positionOS   : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float3 viewWS : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _SpecularColor;
                half _Smoothness;
            CBUFFER_END

            half LightingClearcoatSpecularModifier(half3 lightDir, half3 normal, half3 viewDir, half smoothness)
            {
                //float3 halfVec = SafeNormalize(float3(lightDir) + float3(viewDir));
                //half NdotH = saturate(dot(normal, halfVec));
                //half modifier = pow(NdotH, smoothness);

                half NdotV = saturate(dot(normal,viewDir));
                half modifier = pow(NdotV,smoothness);

                return modifier;
            }

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

                half3 worldNormalDir = normalize(i.normalWS);
                half3 worldViewDir = normalize(i.viewWS);

                half modifier = LightingClearcoatSpecularModifier(lightDir,worldNormalDir,worldViewDir,_Smoothness);

                half3 specularColor = lerp(half3(0, 0, 0), lightColor * _SpecularColor.rgb, smoothstep(0.5 - modifier * 0.5,0.5 + modifier * 0.5,modifier));

                FinalColor= half4(specularColor,1);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
