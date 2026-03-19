Shader "Custom/Character/JapaneseToonSkin"
{
    Properties
    {
        [Header(Base)]
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _BaseMap ("Base Texture", 2D) = "white" {}
        
        [Header(Shadow)]
        _ShadowColor ("Shadow Color", Color) = (0.8,0.6,0.6,1)
        _ShadowThreshold ("Shadow Threshold", Range(0,1)) = 0.5
        _ShadowFeather ("Shadow Feather", Range(0.001,1)) = 0.05
        
        [Header(Ramp)]
        _RampMap ("Ramp Texture", 2D) = "white" {}
        _RampIntensity ("Ramp Intensity", Range(0,1)) = 1.0
        
        [Header(SSS)]
        _SSSColor ("SSS Color", Color) = (1,0.5,0.5,1)
        _SSSIntensity ("SSS Intensity", Range(0,2)) = 0.5
        _SSSDistortion ("SSS Distortion", Range(0,1)) = 0.5
        _SSSPower ("SSS Power", Range(1,16)) = 4.0
        
        [Header(Specular)]
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _SpecularGloss ("Specular Gloss", Range(8,256)) = 32
        _SpecularIntensity ("Specular Intensity", Range(0,2)) = 0.3
        _SpecularThreshold ("Specular Threshold", Range(0,1)) = 0.5
        [NoScaleOffset] _SpecularMap ("Specular Map", 2D) = "white" {}
        
        [Header(Rim Light)]
        _RimColor ("Rim Color", Color) = (1,1,1,1)
        _RimPower ("Rim Power", Range(0.1,8)) = 3.0
        _RimIntensity ("Rim Intensity", Range(0,2)) = 0.5
        [NoScaleOffset] _RimMask ("Rim Mask", 2D) = "white" {}
        
        [Header(Normal)]
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _NormalScale ("Normal Scale", Range(0,2)) = 1.0
        
        [Header(Occlusion)]
        [NoScaleOffset] _OcclusionMap ("Occlusion Map", 2D) = "white" {}
        _OcclusionStrength ("Occlusion Strength", Range(0,1)) = 1.0
        
        [Header(Advanced)]
        _AmbientIntensity ("Ambient Intensity", Range(0,2)) = 1.0
    }
    
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque" 
            "RenderPipeline"="UniversalPipeline"
            "Queue"="Geometry"
        }
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
            
            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _SSS_ON
            #pragma shader_feature _SPECULARMAP
            #pragma shader_feature _RIMASK
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_RampMap);
            SAMPLER(sampler_RampMap);
            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);
            TEXTURE2D(_OcclusionMap);
            SAMPLER(sampler_OcclusionMap);
            TEXTURE2D(_SpecularMap);
            SAMPLER(sampler_SpecularMap);
            TEXTURE2D(_RimMask);
            SAMPLER(sampler_RimMask);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
                float4 _ShadowColor;
                float _ShadowThreshold;
                float _ShadowFeather;
                float _RampIntensity;
                float4 _SSSColor;
                float _SSSIntensity;
                float _SSSDistortion;
                float _SSSPower;
                float4 _SpecularColor;
                float _SpecularGloss;
                float _SpecularIntensity;
                float _SpecularThreshold;
                float4 _RimColor;
                float _RimPower;
                float _RimIntensity;
                float _NormalScale;
                float _OcclusionStrength;
                float _AmbientIntensity;
            CBUFFER_END
            
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
                
                output.viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
                output.fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
                
                return output;
            }
            
            half4 frag(Varyings input) : SV_Target
            {
                // ========================================
                // 1. 基础采样阶段
                // ========================================
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                half3 albedo = baseMap.rgb * _BaseColor.rgb;
                
                // ========================================
                // 2. 法线处理阶段
                // ========================================
                half3 N;
                #ifdef _NORMALMAP
                half4 normalMap = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv);
                half3 normalTS = UnpackNormalScale(normalMap, _NormalScale);
                
                float sgn = input.tangentWS.w;
                float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                N = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
                N = NormalizeNormalPerPixel(N);
                #else
                N = NormalizeNormalPerPixel(input.normalWS);
                #endif
                
                half3 V = normalize(input.viewDirWS);
                
                // ========================================
                // 3. 主光源计算阶段
                // ========================================
                float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                Light mainLight = GetMainLight(shadowCoord);
                half3 L = normalize(mainLight.direction);
                half3 H = normalize(V + L);
                
                float NdotL = dot(N, L);
                float NdotV = max(dot(N, V), 0.001);
                float NdotH = saturate(dot(N, H));
                
                // ========================================
                // 4. 阴影分层阶段
                // ========================================
                float shadowArea = smoothstep(_ShadowThreshold - _ShadowFeather, _ShadowThreshold + _ShadowFeather, NdotL);
                
                // Ramp贴图采样
                float rampU = NdotL * 0.5 + 0.5;
                half3 rampColor = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(rampU, 0.5)).rgb;
                
                // 混合阴影颜色和Ramp颜色
                half3 shadowTint = lerp(_ShadowColor.rgb, half3(1,1,1), shadowArea);
                shadowTint = lerp(shadowTint, rampColor, _RampIntensity);
                
                // 应用阴影到基础颜色
                half3 diffuse = albedo * shadowTint * mainLight.color;
                diffuse *= mainLight.distanceAttenuation * mainLight.shadowAttenuation;
                
                // ========================================
                // 5. 高光计算阶段
                // ========================================
                half specularMask = 1.0;
                #ifdef _SPECULARMAP
                specularMask = SAMPLE_TEXTURE2D(_SpecularMap, sampler_SpecularMap, input.uv).r;
                #endif
                float spec = pow(NdotH, _SpecularGloss);
                spec = step(_SpecularThreshold, spec);
                half3 specular = spec * _SpecularColor.rgb * _SpecularIntensity * mainLight.color * specularMask;
                specular *= shadowArea;
                
                // ========================================
                // 6. 边缘光计算阶段
                // ========================================
                half rimMask = 1.0;
                #ifdef _RIMASK
                rimMask = SAMPLE_TEXTURE2D(_RimMask, sampler_RimMask, input.uv).r;
                #endif
                float rim = 1.0 - NdotV;
                rim = pow(rim, _RimPower);
                half3 rimLight = rim * _RimColor.rgb * _RimIntensity * rimMask;
                
                // ========================================
                // 7. SSS计算阶段
                // ========================================
                half3 sssContribution = half3(0,0,0);
                #ifdef _SSS_ON
                half3 L_distorted = L + N * _SSSDistortion;
                float VdotL = saturate(dot(V, -L_distorted));
                float sss = pow(VdotL, _SSSPower) * _SSSIntensity;
                sssContribution = sss * _SSSColor.rgb * mainLight.color;
                #endif
                
                // ========================================
                // 8. 额外光源阶段
                // ========================================
                half3 additionalLighting = half3(0,0,0);
                #ifdef _ADDITIONAL_LIGHTS
                uint pixelLightCount = GetAdditionalLightsCount();
                for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
                {
                    Light light = GetAdditionalLight(lightIndex, input.positionWS);
                    half3 L_add = normalize(light.direction);
                    float NdotL_add = dot(N, L_add);
                    
                    float shadowArea_add = smoothstep(_ShadowThreshold - _ShadowFeather, _ShadowThreshold + _ShadowFeather, NdotL_add);
                    half3 diffuse_add = albedo * shadowArea_add * light.color;
                    diffuse_add *= light.distanceAttenuation * light.shadowAttenuation;
                    
                    additionalLighting += diffuse_add;
                }
                #endif
                
                // ========================================
                // 9. 环境光阶段
                // ========================================
                half occlusion = lerp(1.0, SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, input.uv).r, _OcclusionStrength);
                half3 ambient = SampleSH(N) * albedo * _AmbientIntensity * occlusion;
                
                // ========================================
                // 10. 最终合成阶段
                // ========================================
                half3 finalColor = diffuse + specular + rimLight + sssContribution + additionalLighting + ambient;
                finalColor = MixFog(finalColor, input.fogFactor);
                
                return half4(finalColor, baseMap.a);
            }
            
            ENDHLSL
        }
        
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }
            
            ZWrite On
            ZTest LEqual
            ColorMask 0
            
            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };
            
            float3 _LightDirection;
            
            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
                
                #if UNITY_REVERSED_Z
                output.positionCS.z = min(output.positionCS.z, output.positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                output.positionCS.z = max(output.positionCS.z, output.positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                
                return output;
            }
            
            half4 ShadowPassFragment(Varyings input) : SV_TARGET
            {
                return 0;
            }
            
            ENDHLSL
        }
        
        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode"="DepthNormals" }
            
            ZWrite On
            ZTest LEqual
            
            HLSLPROGRAM
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
            };
            
            Varyings DepthNormalsVertex(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                return output;
            }
            
            half4 DepthNormalsFragment(Varyings input) : SV_TARGET
            {
                return half4(normalize(input.normalWS), 0);
            }
            
            ENDHLSL
        }
    }
    
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
