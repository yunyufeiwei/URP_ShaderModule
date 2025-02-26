Shader "Art_URP/Base/Light/Oren-Nayer"
{
    Properties
    {
        _Roughness("Roughness",Range(0.01 , 8)) = 1
        _Color("Color" ,Color) = (1,1,1,1)
        [Toggle(_USESMIPLEALGORITHM_0N)]_UseSmiplealgorithm("UseSmiplealgorithm",float) = 1
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

            #pragma shader_feature _USESMIPLEALGORITHM_0N

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
                float3 normalWS     : TEXCOORD0;
                float3 viewWS       : TEXCOORD1;
            };
            
            CBUFFER_START(UnityPerMaterial)
            float _Roughness;
            float4 _Color;
            CBUFFER_END

            //简单算法
            half3 LightingOrenNayerSimple(half3 lightColor , half3 lightDirWS , half3 normalWS , half3 viewDirWS , half3 diffuseColor , half roughness)
            {
                half roughnessSqr = roughness * roughness;
                half3 o_n_fraction = roughnessSqr / (roughnessSqr + float3(0.33 , 0.13 , 0.09));
                half3 oren_nayer = float3(1,0,0) + float3(-0.5,0.17,0.45) * o_n_fraction;
                half cos_NdotL = saturate(dot(lightDirWS,normalWS));
                half cos_NdotV = saturate(dot(normalWS,viewDirWS));
                half oren_nayer_s = saturate(dot(lightDirWS,viewDirWS)) - (cos_NdotL * cos_NdotV);
                oren_nayer_s /= lerp(max(cos_NdotL,cos_NdotV) , 1 , step(oren_nayer_s , 0));
                half3 oren_nayerColor = diffuseColor * cos_NdotL * (oren_nayer.x + diffuseColor * oren_nayer.y + oren_nayer.z * oren_nayer_s) * lightColor;
                
                return oren_nayerColor;
            }

            //复杂原始算法
            half3 LightingOrenNayerAlgorithm(half3 lightColor , half3 lightDirWS , half3 normalWS , half3 viewDirWS , half3 diffuseColor , half roughness)
            {
                half NdotL = saturate(dot(normalWS,lightDirWS));
                half NdotV = saturate(dot(normalWS,viewDirWS));
                half theta2 = roughness * roughness;
                half A = 1 - 0.5 * (theta2/(theta2 + 0.33));
                half B = 0.45 *  (theta2/(theta2 + 0.09));
                half cos_NdotL = acos(NdotL);
                half cos_NdotV = acos(NdotV);
                half alpha = max(cos_NdotV,cos_NdotL);
                half beta = min(cos_NdotV,cos_NdotL);
                half gamma = length(viewDirWS - normalWS * NdotV) * length(lightDirWS - normalWS * NdotL);
                half orenNayer = NdotL * (A + B * max(0,gamma) * sin(alpha) * tan(beta));
                half3 orenNayerColor = orenNayer * diffuseColor * lightColor;
                return orenNayerColor;
            }

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                //使用Unity的内置方法，直接计算出时间空间下的试图方向
                o.viewWS = GetWorldSpaceNormalizeViewDir(positionWS);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;

                Light light = GetMainLight();
                half3 lightColor = light.color * light.distanceAttenuation;
                half3 lightDirWS = light.direction;
                half3 worldNormalDir = normalize(i.normalWS);
                half3 worldViewDir = normalize(i.viewWS);

                //如果开启开关就使用简单算法输出，否则就使用复杂算法输出
                #if defined(_USESMIPLEALGORITHM_0N)
                    half3 orenNayerColor = LightingOrenNayerSimple(lightColor , lightDirWS , worldNormalDir , worldViewDir , _Color.rgb , _Roughness);
                    FinalColor = half4(orenNayerColor ,1);
                #else
                    half3 orenNayerColor = LightingOrenNayerAlgorithm(lightColor , lightDirWS , worldNormalDir , worldViewDir , _Color.rgb , _Roughness);
                    FinalColor = half4(orenNayerColor ,1);
                #endif


                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
