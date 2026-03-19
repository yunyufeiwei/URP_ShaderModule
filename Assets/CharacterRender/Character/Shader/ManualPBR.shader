Shader "Mafia/ManualPBR"
{
    Properties
    {
        [MainColor]_BaseColor("Color",Color) = (1,1,1,1)
        [MainTexture]_BaseMap ("Albedo", 2D) = "white" {}
        _MaskMap("MaskMap(MRA)",2D) = "white"{}
        _Roughness("Roughness",Range(0,1)) = 1
        _NormalMap("NormalMap",2D) = "bump"{}
        _NormalScale("NormalScale",float) = 1
        _EmissiveMap("EmissiveMap",2D) = "black"{}
        _EmissiveColor("EmissiveColor",Color) = (1,1,1,1)
        _EmissiveIntensity("EmissiveIntensity",Range(0,10)) = 1
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "IgnoreProjector" = "True"}
        LOD 300

        Pass
        {
            NAME "ForwardLit"
            Tags {"LightMode" = "UniversalForward"}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"
          
            #include "ManualBRDFInput.hlsl"
            #include "ManualBRDF.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                half2  uv           : TEXCOORD0;
                float3 positionWS   : TEXCOORD1;
                half3  normalWS     : TEXCOORD2;
                half4  tangentWS    : TEXCOORD3;
                float4 shadowCoord  : TEXCOORD4;  // 主光源阴影坐标
            };
            
            Varyings vert (Attributes v)
            {
                Varyings o;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS,v.tangentOS);

                o.normalWS = normalInput.normalWS;
                real sign = v.tangentOS.w * GetOddNegativeScale();
                o.tangentWS = half4(normalInput.tangentWS , sign);
                o.positionWS = vertexInput.positionWS;
                o.positionCS = vertexInput.positionCS;

                o.shadowCoord = GetShadowCoord(vertexInput);

                o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
                
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                half4 maskMap = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, i.uv);
                half4 normalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv);
                half3 normalTS = UnpackNormalScale(normalMap, _NormalScale);

                half metallic = maskMap.r;
                half roughness = max(maskMap.g * _Roughness, 0.0078125);
                half occlusion = maskMap.b;
                
                float sgn = i.tangentWS.w;
                float3 bitangent = sgn * cross(i.normalWS.xyz, i.tangentWS.xyz);
                half3 normalWS = normalize(TransformTangentToWorld(normalTS, half3x3(i.tangentWS.xyz, bitangent.xyz, i.normalWS.xyz)));
                normalWS = NormalizeNormalPerPixel(normalWS);

                half3 V = normalize(GetWorldSpaceViewDir(i.positionWS));

                float3 F0 = lerp(float3(0.04,0.04,0.04), baseMap.rgb, metallic);

                Light mainLight = GetMainLight(i.shadowCoord);
                half3 directLighting = Custom_CalculateDirectLightBRDF(mainLight, normalWS, V, baseMap.rgb, metallic, roughness, F0);

                #if defined(_ADDITIONAL_LIGHTS)
                    uint pixelLightCount = GetAdditionalLightsCount();

                    #if defined(_ADDITIONAL_LIGHT_SHADOWS)
                        float4 additionalShadowCoord = float4(0, 0, 0, 0);
                    #endif
                
                    for (uint lightIndex = 0; lightIndex < pixelLightCount; ++lightIndex)
                    {
                        #if defined(_ADDITIONAL_LIGHT_SHADOWS)
                            Light additionalLight = GetAdditionalLight(lightIndex, i.positionWS);
                        #else
                            Light additionalLight = GetAdditionalLight(lightIndex, i.positionWS);
                        #endif
                        
                        directLighting += Custom_CalculateDirectLightBRDF(additionalLight, normalWS, V, baseMap.rgb, metallic, roughness, F0);
                    }
                #endif

                //间接光计算
                half3  indirectDiffuse = SampleSH(normalWS) * occlusion;
                half3 F_indirect = Custom_FresnelSchlickRoughness(normalWS, V, F0, roughness);
                half3 kS_indirect = F_indirect;
                half3 kD_indirect = (1.0 - kS_indirect) * (1.0 - metallic);
                half3 ambientDiffuse = kD_indirect * indirectDiffuse * baseMap.rgb;

                half3 R = reflect(-V, normalWS);
                half  mipLevel = roughness * (1- 0.7 * roughness) * 6.0;
                half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, R, mipLevel);
                half3 indirectSpecular = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
                half3 ambientSpecular = indirectSpecular * F_indirect * occlusion;
                half3 indirectLighting = ambientDiffuse + ambientSpecular;      //最终间接光漫反射和高光反射

                //自发光计算
                half4 emissiveMap = SAMPLE_TEXTURECUBE(_EmissiveMap, sampler_EmissiveMap, i.uv).r;
                half4 EmissiveColor = emissiveMap * _EmissiveColor * _EmissiveIntensity;
                
                half3 finalColor = EmissiveColor + directLighting + indirectLighting;

                //Inner
                // half NdotV = dot(normalWS, V);
                // half innerOutline = 1 - smoothstep(0.42 - 0.1, 0.42, NdotV);
                // half3 innerColor = lerp(finalColor, half3(0.76,0.85,0.85), innerOutline );
                
                return half4(finalColor, baseMap.a);
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma multi_compile_instancing
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            
            ENDHLSL
        }
    }
    CustomEditor  "ManualPBRGUI"
}
