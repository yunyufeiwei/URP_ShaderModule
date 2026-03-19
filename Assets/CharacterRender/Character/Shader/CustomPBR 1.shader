Shader "Custom/PBR/StandardPBR"
{
    Properties
    {
        [Header(Base Maps)]
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Color ("Color Tint", Color) = (1,1,1,1)
        
        [Header(PBR Mask Map)]
        [NoScaleOffset] _MaskMap ("Mask (R-Metallic, G-Roughness, B-AO)", 2D) = "white" {}
        _MetallicScale ("Metallic Scale", Range(0, 1)) = 0.0
        _RoughnessScale ("Roughness Scale", Range(0, 1)) = 0.5
        _AOStrength ("AO Strength", Range(0, 1)) = 1.0
        
        [Header(Normal Map)]
        [Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Normal Scale", Range(0, 2)) = 1.0
        
//        [Header(Reflection)]
//        _ReflectionStrength ("Reflection Strength", Range(0, 1)) = 1.0
//        _ReflectionCubemap ("Reflection Cubemap", Cube) = "" {}
    }
    
    SubShader
    {
        Tags {"RenderPipeline"="UniversalPipeline" "RenderType"="Opaque"  "Queue"="Geometry" }
        LOD 300
        
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _REFLECTION
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
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
                float3 viewDirWS : TEXCOORD4;
                float fogFactor : TEXCOORD5;
                float4 shadowCoord : TEXCOORD6;
            };
            
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_MaskMap); SAMPLER(sampler_MaskMap);
            TEXTURE2D(_BumpMap); SAMPLER(sampler_BumpMap);
            //TEXTURECUBE(_ReflectionCubemap); SAMPLER(sampler_ReflectionCubemap);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _Color;
                float _MetallicScale;
                float _RoughnessScale;
                float _AOStrength;
                float _BumpScale;
                //float _ReflectionStrength;
            CBUFFER_END

            //---F项
            half3 F_Schlick(half VdotH, half3 F0)
            {
                return F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);
            }
            
            half3 F_SchlickR(half cosTheta, half3 F0, half roughness)
            {
                return F0 + (max(half3(1.0-roughness,1.0-roughness,1.0-roughness), F0) - F0) * pow(1.0 - saturate(cosTheta), 5.0);
            }

            //---D项
            half D_GGX1(half3 N, half3 H, half roughness)
            {
                half a = roughness * roughness;
                half a2 = a * a;
                half NdotH = max(dot(N,H), 0);
                half NdotH2 = NdotH * NdotH;

                half nom = a2;
                half denom = NdotH2 * (a2 - 1.0) + 1.0;
                denom = PI * denom * denom;
                
                return nom / denom;
            }

            //---G项
            half G_SchlickGGX(half NdotV, half roughness)
            {
                float r = roughness + 1;
                float k = (r * r) / 8.0;
                float nom = NdotV;
                float denom = NdotV * (1 - k) + k + 0.0000001;
                
                return nom / denom;
            }
            
            half G_Smith(half NdotV, half NdotL, half roughness)
            {
                float ggx1 = G_SchlickGGX(NdotV,roughness);
                float ggx2 = G_SchlickGGX(NdotL,roughness);
                return ggx1 * ggx2;
            }
            
            half3 BRDF(half3 albedo, half metallic, half roughness, half3 N, half3 V, Light light)
            {
                half3 L = normalize(light.direction);
                half3 H = normalize(V + L);
                half NdotL = saturate(dot(N, L));
                half NdotV = saturate(dot(N, V));
                half NdotH = saturate(dot(N, H));
                half VdotH = saturate(dot(V, H));
                if(NdotL <= 0.0) return 0;
                half3 F0 = lerp(0.04, albedo, metallic);
                half3 F = F_Schlick(VdotH, F0);
                half3 spec = (D_GGX1(N , H , roughness) * G_Smith(NdotV,NdotL,roughness) * F) / max(4.0*NdotV*NdotL, 0.001);
                half3 diff = ((1.0-metallic)*albedo);// ((1.0-F)*(1.0-metallic)*albedo);
                return (diff+spec)*light.color*light.distanceAttenuation*light.shadowAttenuation*NdotL;
            }
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                
                output.positionWS = vertexInput.positionWS;
                output.positionCS = vertexInput.positionCS;
                
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                
                output.normalWS = normalInput.normalWS;
                output.tangentWS = float4(normalInput.tangentWS, input.tangentOS.w);
                output.viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
                
                output.fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
                output.shadowCoord = GetShadowCoord(vertexInput);
                
                return output;
            }
            
            half4 frag(Varyings input) : SV_Target
            {
                //采样准备好的纹理数据
                half4 baseMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv) * _Color;
                half3 albedo = baseMap.rgb;
                half  alpha = baseMap.a;
                half4 mask = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, input.uv);
                half  metallic = saturate(mask.r * _MetallicScale);
                half  roughness = saturate(mask.g * _RoughnessScale);
                half  ao = lerp(1.0, mask.b, _AOStrength);
                //roughness = max(roughness, 0.002);
                
                half3 normalWS = normalize(input.normalWS);
                #ifdef _NORMALMAP
                    half3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv), _BumpScale);
                    half3 bitangent = cross(input.normalWS, input.tangentWS.xyz) * input.tangentWS.w;
                    normalWS = normalize(mul(normalTS, half3x3(input.tangentWS.xyz, bitangent, input.normalWS)));
                #endif

                //准备BRDF所需的向量
                Light mainLight = GetMainLight(input.shadowCoord);

                half3 L = normalize(mainLight.direction);
                half3 V = normalize(input.viewDirWS);
                half3 H = normalize(V + L);
                half3 N = normalize(normalWS);
                half NdotL = saturate(dot(N, L));
                half NdotV = saturate(dot(N, V));
                half VdotH = saturate(dot(V, H));
                half3 F0 = lerp(0.04, albedo, metallic);
                half3 Lo = 0;

                Lo += BRDF(albedo, metallic, roughness, normalWS, V, mainLight);

                //计算额外的点光源
                #ifdef _ADDITIONAL_LIGHTS
                    uint pixelLightCount = GetAdditionalLightsCount();
                    for(uint i=0u; i<pixelLightCount; ++i)
                    {
                        Light light = GetAdditionalLight(i, input.positionWS, half4(1,1,1,1));
                        Lo += BRDF(albedo, metallic, roughness, normalWS, V, light);
                    }
                #endif
                
                half3 ambient = SampleSH(normalWS) * albedo * (1.0-metallic) * ao;
                
                half3 reflection = 0;

                #ifdef _REFLECTION
                    half3 R = reflect(-V, normalWS);
                    half mip = roughness * (1.0 - metallic) * 7.0; // 金属度会影响反射清晰度
                    
                    half4 envSample = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, R, mip);
                    half3 envRGB = DecodeHDREnvironment(envSample, unity_SpecCube0_HDR);
                    
                    // 金属使用albedo染色，非金属使用F0染色
                    half3 F = F_SchlickR(NdotV, F0, roughness);
                    half3 specularIBL = envRGB * F;
                    
                    // 漫反射IBL（可选）
                    half3 diffuseIBL = SampleSH(normalWS) * albedo * (1.0 - metallic);
                    
                    reflection = (diffuseIBL + specularIBL) * _ReflectionStrength;
                #endif
                
                half3 color = (Lo + ambient + reflection) * ao;
                color = MixFog(color, input.fogFactor);
                return half4(color, alpha);
            }
            ENDHLSL
        }
        
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back
            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
        
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}
            ZWrite On
            ColorMask 0
            Cull Back
            HLSLPROGRAM
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}