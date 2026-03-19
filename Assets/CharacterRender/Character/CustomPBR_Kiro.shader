Shader "Custom/PBR/CustomPBR"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _BaseMap ("Albedo (RGB)", 2D) = "white" {}
        
        // 合并贴图：R=Metallic, G=Roughness, B=AO
        _MaskMap ("Mask Map (R=Metallic, G=Roughness, B=AO)", 2D) = "white" {}
        _Metallic ("Metallic", Range(0,1)) = 1.0
        _Smoothness ("Smoothness", Range(0,1)) = 0.5
        
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Normal Scale", Float) = 1.0
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        LOD 200
        
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fog
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_MaskMap);
            SAMPLER(sampler_MaskMap);
            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
                float _BumpScale;
                float _Metallic;
                float _Smoothness;
            CBUFFER_END
            
            #define PI 3.14159265359
            #define MIN_ROUGHNESS 0.0078125
            
            // ============================================
            // Cook-Torrance BRDF 组件
            // ============================================
            
            // D项：GGX / Trowbridge-Reitz 法线分布函数
            float DistributionGGX(float NdotH, float roughness)
            {
                float alpha = roughness * roughness;
                float alpha2 = alpha * alpha;
                float NdotH2 = NdotH * NdotH;
                
                float numerator = alpha2;
                float denominator = NdotH2 * (alpha2 - 1.0) + 1.0;
                denominator = PI * denominator * denominator;
                
                // 使用更大的epsilon避免除零，同时增强高光
                return numerator / max(denominator, 0.0000001);
            }
            
            // G项：Smith's Schlick-GGX 几何遮蔽函数
            float GeometrySchlickGGX(float NdotV, float roughness)
            {
                float r = roughness + 1.0;
                float k = (r * r) / 8.0;
                
                float numerator = NdotV;
                float denominator = NdotV * (1.0 - k) + k;
                
                return numerator / max(denominator, 0.0000001);
            }
            
            float GeometrySmith(float NdotV, float NdotL, float roughness)
            {
                float ggx1 = GeometrySchlickGGX(NdotL, roughness);
                float ggx2 = GeometrySchlickGGX(NdotV, roughness);
                return ggx1 * ggx2;
            }
            
            // F项：Fresnel-Schlick 菲涅尔方程
            float3 FresnelSchlick(float HdotV, float3 F0)
            {
                return F0 + (1.0 - F0) * pow(saturate(1.0 - HdotV), 5.0);
            }
            
            // F项的粗糙度版本：用于环境光的菲涅尔计算
            float3 FresnelSchlickRoughness(float NdotV, float3 F0, float roughness)
            {
                float smoothness = 1.0 - roughness;
                return F0 + (max(float3(smoothness, smoothness, smoothness), F0) - F0) * pow(saturate(1.0 - NdotV), 5.0);
            }
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float4 tangentWS : TEXCOORD3;
                float fogFactor : TEXCOORD4;
            };
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                
                output.normalWS = normalInput.normalWS;
                real sign = input.tangentOS.w * GetOddNegativeScale();
                output.tangentWS = float4(normalInput.tangentWS.xyz, sign);
                
                output.fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
                
                return output;
            }
            
            half4 frag(Varyings input) : SV_Target
            {
                // ========================================
                // 1. 采样贴图
                // ========================================
                half4 albedoAlpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                half3 albedo = albedoAlpha.rgb * _BaseColor.rgb;
                
                half4 maskMap = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, input.uv);
                half metallic = maskMap.r * _Metallic;
                half roughnessFromMap = maskMap.g;
                half roughness = max(roughnessFromMap * (1.0 - _Smoothness), MIN_ROUGHNESS);
                half occlusion = maskMap.b;
                
                half4 normalMap = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv);
                half3 normalTS = UnpackNormalScale(normalMap, _BumpScale);
                
                // ========================================
                // 2. 转换法线到世界空间
                // ========================================
                float sgn = input.tangentWS.w;
                float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                half3 N = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
                N = NormalizeNormalPerPixel(N);

                // ========================================
                // 3. 计算光照向量
                // ========================================
                half3 V = normalize(GetCameraPositionWS() - input.positionWS);
                float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                Light mainLight = GetMainLight(shadowCoord);
                half3 L = mainLight.direction;
                half3 H = normalize(V + L);
                
                // ========================================
                // 4. 计算所需的点积
                // ========================================
                float NdotL = saturate(dot(N, L));
                // 确保NdotV不会太小，避免高光被过度削弱
                float NdotV = max(abs(dot(N, V)), 0.001);
                float NdotH = saturate(dot(N, H));
                float HdotV = saturate(dot(H, V));
                
                // ========================================
                // 5. 计算F0（基础反射率）
                // ========================================
                float3 F0 = lerp(float3(0.04, 0.04, 0.04), albedo, metallic);
                
                // ========================================
                // 6. Cook-Torrance 镜面反射 BRDF
                // ========================================
                float D = DistributionGGX(NdotH, roughness);
                float G = GeometrySmith(NdotV, NdotL, roughness);
                float3 F = FresnelSchlick(HdotV, F0);
                
                // 调整分母以获得更强的高光
                // Unity Lit shader使用了更小的分母来增强高光效果
                float3 specularBRDF = (D * G * F) / max(4.0 * NdotV * NdotL, 0.001);
                
                // ========================================
                // 7. 能量守恒
                // ========================================
                float3 kS = F;
                float3 kD = (1.0 - kS) * (1.0 - metallic);
                
                // ========================================
                // 8. Lambert 漫反射 BRDF
                // 注意：Unity的Lit shader为了视觉效果，不除以PI
                // 这样可以获得更亮的漫反射效果
                // ========================================
                float3 diffuseBRDF = kD * albedo;
                
                // ========================================
                // 9. 主光源直接光照
                // ========================================
                float3 directLighting = (diffuseBRDF + specularBRDF) * mainLight.color * NdotL;
                directLighting *= mainLight.distanceAttenuation * mainLight.shadowAttenuation;
                
                // ========================================
                // 10. 额外光源
                // ========================================
                #ifdef _ADDITIONAL_LIGHTS
                uint pixelLightCount = GetAdditionalLightsCount();
                for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
                {
                    Light light = GetAdditionalLight(lightIndex, input.positionWS);
                    half3 L_add = light.direction;
                    half3 H_add = normalize(V + L_add);
                    
                    float NdotL_add = saturate(dot(N, L_add));
                    float NdotH_add = saturate(dot(N, H_add));
                    float HdotV_add = saturate(dot(H_add, V));
                    
                    float D_add = DistributionGGX(NdotH_add, roughness);
                    float G_add = GeometrySmith(NdotV, NdotL_add, roughness);
                    float3 F_add = FresnelSchlick(HdotV_add, F0);
                    
                    float3 specularBRDF_add = (D_add * G_add * F_add) / max(4.0 * NdotV * NdotL_add, 0.001);
                    float3 kS_add = F_add;
                    float3 kD_add = (1.0 - kS_add) * (1.0 - metallic);
                    float3 diffuseBRDF_add = kD_add * albedo;
                    
                    float3 additionalLighting = (diffuseBRDF_add + specularBRDF_add) * light.color * NdotL_add;
                    additionalLighting *= light.distanceAttenuation * light.shadowAttenuation;
                    
                    directLighting += additionalLighting;
                }
                #endif
                
                // ========================================
                // 11. 环境光照（IBL）
                // ========================================
                half3 indirectDiffuse = SampleSH(N);
                
                float3 F_indirect = FresnelSchlickRoughness(NdotV, F0, roughness);
                float3 kS_indirect = F_indirect;
                float3 kD_indirect = (1.0 - kS_indirect) * (1.0 - metallic);
                
                // 漫反射环境光
                float3 ambientDiffuse = kD_indirect * albedo * indirectDiffuse;
                
                // 镜面反射环境光
                half3 R = reflect(-V, N);
                half perceptualRoughness = roughness;
                half mipLevel = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness) * 6.0;
                
                half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, R, mipLevel);
                half3 indirectSpecular = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
                
                // 组合环境光并应用AO
                float3 indirectLighting = (ambientDiffuse + indirectSpecular * F_indirect) * occlusion;
                
                // ========================================
                // 12. 组合最终颜色
                // ========================================
                float3 finalColor = directLighting + indirectLighting;
                finalColor = MixFog(finalColor, input.fogFactor);
                
                return half4(finalColor, albedoAlpha.a);
            }
            
            ENDHLSL
        }
    }
    
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
