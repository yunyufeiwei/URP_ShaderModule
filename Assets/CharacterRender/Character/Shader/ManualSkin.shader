Shader "Mafia/ManualSkin"
{
    Properties
    {
        // 基础纹理属性
        _BaseMap("BaseMap", 2D) = "white" {}
        _LitColor("LitColor+Alpha", Color) = (1,1,1,1)
        _ShadeColor("ShadeColor", Color) = (0.97,0.81,0.86,1)
        
        // 法线贴图属性
        _NormalMap("NormalMap", 2D) = "bump" {}
        _NormalScale("NormalScale", Float) = 1.0
        
        // 卡通光照属性
        _ShadeShift("ShadeShift", Range(-1,1)) = 0       // 阴影偏移
        _ShadeToony("ShadeToony", Range(0,1)) = 0.9      // 阴影卡通化程度
        _IndirectLightIntensity("IndirectLightIntensity", Range(0,1)) = 1
        
        // 阴影和光照等级贴图（隐藏属性）
        [HideInInspector]_ReceiveShadowRate ("Receive Shadow", Range(0, 1)) = 1
        [HideInInspector][NoScaleOffset] _ReceiveShadowTexture ("Receive Shadow Texture", 2D) = "white" {}
        [HideInInspector]_ShadingGradeRate ("Shading Grade", Range(0, 1)) = 1
        [HideInInspector][NoScaleOffset] _ShadingGradeTexture ("Shading Grade Texture", 2D) = "white" {}
        
        // 高光属性
        [Toggle(_USESPECULAR)] _USESPECULAR("Use Specular", Float) = 0
        _SpecularPow("SpecularPow", Range(0, 100)) = 20   // 提高范围以增强卡通高光效果
        _SpecularColor("SpecularColor", Color) = (1,1,1,1)
        _SpecularIntensity("SpecularIntensity", Range(0, 5)) = 1.0 // 高光强度
        
        // 点光源属性
        [Toggle(_USE_ADDitionLIGHT)] _USE_ADDitionLIGHT("Use Point Light", Float) = 0
        _PointLightIntensity("Point Light Intensity", Range(0, 5)) = 1.0
        _PointLightToony("Point Light Toony", Range(0,1)) = 0.9 // 点光源卡通化程度
        
        [Toggle(_USE_INNER_OUTLINE)] _USE_INNER_OUTLINE("Use Inner Outline", Float) = 0
        _InnerOutlineColor("Inner Outline Color", Color) = (0.1,0.1,0.1,1)
        _InnerOutlineThreshold("Inner Outline Threshold", Range(0, 1)) = 0.2
        
        // 描边属性
        [Toggle(_USE_OUTLINE)] _USE_OUTLINE("Use Outer Outline", Float) = 0
        _OutlineColor("Outline Color", Color) = (0,0,0,1)
        _OutlineWidth("Outline Width", Range(0, 1)) = 1
        
        [Toggle(MTOON_OUTLINE_WIDTH_WORLD)] MTOON_OUTLINE_WIDTH_WORLD("MTOON_OUTLINE_WIDTH_WORLD", Float) = 0
        [Toggle(MTOON_OUTLINE_WIDTH_SCREEN)] MTOON_OUTLINE_WIDTH_SCREEN("MTOON_OUTLINE_WIDTH_SCREEN", Float) = 0
        [Toggle(MTOON_OUTLINE_WIDTH_WORLD_VERTEX_COLOR)] MTOON_OUTLINE_WIDTH_WORLD_VERTEX_COLOR("MTOON_OUTLINE_WIDTH_WORLD_VERTEX_COLOR", Float) = 0
        [Toggle(MTOON_OUTLINE_WIDTH_SCREEN_VERTEX_COLOR)] MTOON_OUTLINE_WIDTH_SCREEN_VERTEX_COLOR("MTOON_OUTLINE_WIDTH_SCREEN_VERTEX_COLOR", Float) = 0
        
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry" "IgnoreProjector" = "True"}
        LOD 100

        Pass
        {
            Name "OuterOutline"
            Tags { "LightMode" = "SRPDefaultUnlit" }
            
            Cull Front
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _USE_OUTLINE
            #pragma multi_compile _ MTOON_OUTLINE_WIDTH_WORLD MTOON_OUTLINE_WIDTH_SCREEN MTOON_OUTLINE_WIDTH_WORLD_VERTEX_COLOR MTOON_OUTLINE_WIDTH_SCREEN_VERTEX_COLOR

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "OutlinePass.hlsl"
            ENDHLSL
        }

        // 主渲染Pass
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // 通用编译宏
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _NORMALMAP
            #pragma multi_compile _ _USESPECULAR
            #pragma multi_compile _ _USE_ADDitionLIGHT
            #pragma multi_compile _ _USE_INNER_OUTLINE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS

            // 包含必要的库
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float4 color        : COLOR;
                float2 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 positionWS   : TEXCOORD0;
                float3 tspace0      : TEXCOORD1;
                float3 tspace1      : TEXCOORD2;
                float3 tspace2      : TEXCOORD3;
                float2 uv           : TEXCOORD4;
                float4 color        : TEXCOORD5;
                float4 shadowCoord  : TEXCOORD6;
                float3 viewDirWS    : TEXCOORD7; // 视图方向（用于内描边）
            };

            // 纹理和采样器
            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
            TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
            TEXTURE2D(_ReceiveShadowTexture); SAMPLER(sampler_ReceiveShadowTexture);
            TEXTURE2D(_ShadingGradeTexture); SAMPLER(sampler_ShadingGradeTexture);

            // 材质参数
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _LitColor;
                float4 _ShadeColor;
                float _NormalScale;
                float _ShadeShift;
                float _ShadeToony;
                float _ReceiveShadowRate;
                float _ShadingGradeRate;
                float _IndirectLightIntensity;
                
                // 高光参数
                float _SpecularPow;
                float4 _SpecularColor;
                float _SpecularIntensity;
                
                // 点光源参数
                float _PointLightIntensity;
                float _PointLightToony;
                
                // 内描边参数
                float4 _InnerOutlineColor;
                float _InnerOutlineThreshold;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionHCS = vertexInput.positionCS;
                o.positionWS = vertexInput.positionWS;

                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS.xyz, v.tangentOS);
                half tangentSign = v.tangentOS.w * GetOddNegativeScale();
                half3 worldBitangent = cross(normalInput.normalWS, normalInput.tangentWS) * tangentSign;
                o.tspace0 = half3(normalInput.tangentWS.x, worldBitangent.x, normalInput.normalWS.x);
                o.tspace1 = half3(normalInput.tangentWS.y, worldBitangent.y, normalInput.normalWS.y);
                o.tspace2 = half3(normalInput.tangentWS.z, worldBitangent.z, normalInput.normalWS.z);

                o.shadowCoord = GetShadowCoord(vertexInput);

                o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
                o.color = v.color;
                o.viewDirWS = normalize(GetWorldSpaceViewDir(o.positionWS));
                return o;
            }

            half CalculateCelShading(half NdotL, half toonyFactor, half shift)
            {
                return smoothstep(shift, shift + (1 - toonyFactor), NdotL);
            }

            half4 frag (Varyings i) : SV_Target
            {
                // 采样基础纹理
                half4 baseTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                if (baseTex.a < 0.1) discard; // 透明像素直接丢弃

                // 采样法线贴图并转换到世界空间
                half3 worldNormal;
                #ifdef _NORMALMAP
                    half3 tangentNormal = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv), _NormalScale);
                    worldNormal = normalize(half3(
                        dot(i.tspace0, tangentNormal),
                        dot(i.tspace1, tangentNormal),
                        dot(i.tspace2, tangentNormal)
                    ));
                #else
                    worldNormal = normalize(half3(i.tspace0.z, i.tspace1.z, i.tspace2.z));
                #endif

                // 主光源计算
                Light mainLight = GetMainLight(i.shadowCoord);
                half3 lightDirWS = normalize(mainLight.direction);
                half NdotL_main = dot(worldNormal, lightDirWS);
                half attenuation = mainLight.distanceAttenuation * mainLight.shadowAttenuation;

                // 阴影和光照等级遮罩
                half receiveShadow = SAMPLE_TEXTURE2D(_ReceiveShadowTexture, sampler_ReceiveShadowTexture, i.uv).r * _ReceiveShadowRate;
                half shadingGrade = SAMPLE_TEXTURE2D(_ShadingGradeTexture, sampler_ShadingGradeTexture, i.uv).r * _ShadingGradeRate;

                // 主光源卡通光照计算
                half mainLightCel = CalculateCelShading(NdotL_main, _ShadeToony, _ShadeShift);
                mainLightCel = mainLightCel * receiveShadow * shadingGrade;
                
                // 间接光照
                half3 indirectLight = _IndirectLightIntensity * SampleSH(worldNormal);
                
                // 主光源最终光照
                half3 directLighting = mainLightCel * mainLight.color.rgb * attenuation;
                half3 totalLighting = directLighting + indirectLight;

                #ifdef _USE_ADDitionLIGHT
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
                        half NdotL = dot(worldNormal,additionalLight.direction);
                        totalLighting += CalculateCelShading(NdotL, _PointLightToony, _ShadeShift);
                    }
                #endif

                // 高光计算
                half3 specular = 0;
                #ifdef _USESPECULAR
                    half3 viewDirWS = normalize(GetWorldSpaceViewDir(i.positionWS));
                    half3 halfDirWS = normalize(lightDirWS + viewDirWS);
                    half NdotH = saturate(dot(worldNormal, halfDirWS));
                    specular = pow(NdotH, _SpecularPow) * _SpecularColor.rgb * _SpecularIntensity;
                #endif

                // 基础颜色混合
                half3 litColor = _LitColor.rgb;
                half3 shadeColor = _ShadeColor.rgb;
                half3 baseColor = lerp(shadeColor, litColor, saturate(totalLighting)) * baseTex.rgb;

                // 内描边计算
                #ifdef _USE_INNER_OUTLINE
                    half NdotV = dot(worldNormal, i.viewDirWS);
                    half innerOutline = 1 - smoothstep(_InnerOutlineThreshold - 0.1, _InnerOutlineThreshold, NdotV);
                    baseColor = lerp(baseColor, _InnerOutlineColor.rgb, innerOutline * _InnerOutlineColor.a);
                #endif

                // 最终颜色
                half3 finalColor = baseColor + specular;
                finalColor = saturate(finalColor); // 防止颜色过曝

                return half4(finalColor, _LitColor.a * baseTex.a);
            }
            ENDHLSL
        }

        // 阴影投射Pass
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };

            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionHCS = vertexInput.positionCS;
                o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                half4 baseTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                if (baseTex.a < 0.1) discard;
                return 0;
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}