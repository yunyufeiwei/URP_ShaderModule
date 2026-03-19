Shader "VRM/MToon_URP"
{
    Properties
    {
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
        _Color ("Lit Color + Alpha", Color) = (1,1,1,1)
        _ShadeColor ("Shade Color", Color) = (0.97, 0.81, 0.86, 1)
        
        [NoScaleOffset] _MainTex ("Lit Texture + Alpha", 2D) = "white" {}
        [NoScaleOffset] _ShadeTexture ("Shade Texture", 2D) = "white" {}
        
        _BumpScale ("Normal Scale", Float) = 1.0
        [Normal] _BumpMap ("Normal Texture", 2D) = "bump" {}
        
        _ReceiveShadowRate ("Receive Shadow", Range(0, 1)) = 1
        [NoScaleOffset] _ReceiveShadowTexture ("Receive Shadow Texture", 2D) = "white" {}
        _ShadingGradeRate ("Shading Grade", Range(0, 1)) = 1
        [NoScaleOffset] _ShadingGradeTexture ("Shading Grade Texture", 2D) = "white" {}
        _ShadeShift ("Shade Shift", Range(-1, 1)) = 0
        _ShadeToony ("Shade Toony", Range(0, 1)) = 0.9
        _LightColorAttenuation ("Light Color Attenuation", Range(0, 1)) = 0
        _IndirectLightIntensity ("Indirect Light Intensity", Range(0, 1)) = 0.1
        [NoScaleOffset] _SphereAdd ("Sphere Texture(Add)", 2D) = "black" {}
        _EmissionColor ("Color", Color) = (0,0,0)
        [NoScaleOffset] _EmissionMap ("Emission", 2D) = "white" {}
        [NoScaleOffset] _OutlineWidthTexture ("Outline Width Tex", 2D) = "white" {}
		_OutlineWidth("Outline Width", Range(0.01, 1)) = 0.5
		_OutlineUseSoftNormal("Outline Use Soft Normal", Range(0.0, 1)) = 0.0
        _OutlineScaledMaxDistance ("Outline Scaled Max Distance", Range(1, 10)) = 1
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _OutlineLightingMix ("Outline Lighting Mix", Range(0, 1)) = 1

        [HideInInspector] _DebugMode ("_DebugMode", Float) = 0.0
        [HideInInspector] _BlendMode ("_BlendMode", Float) = 0.0
        [HideInInspector] _OutlineWidthMode ("_OutlineWidthMode", Float) = 0.0
        [HideInInspector] _OutlineColorMode ("_OutlineColorMode", Float) = 0.0
        [HideInInspector] _CullMode ("_CullMode", Float) = 2.0
        [HideInInspector] _OutlineCullMode ("_OutlineCullMode", Float) = 1.0
        [HideInInspector] _SrcBlend ("_SrcBlend", Float) = 1.0
        [HideInInspector] _DstBlend ("_DstBlend", Float) = 0.0
        [HideInInspector] _ZWrite ("_ZWrite", Float) = 1.0
    }
    
    SubShader
    {
        Tags { 
            "RenderType" = "Opaque" 
            "Queue" = "Geometry"
            "RenderPipeline" = "UniversalPipeline" // URP标识
        }
        
        // Forward Base (URP Main Light)
        Pass 
        {
            Name "FORWARD_BASE"
            Tags { "LightMode" = "UniversalForward" } // URP光照模式

            Cull [_CullMode]
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            ZTest LEqual
            BlendOp Add, Max

            HLSLPROGRAM
            #pragma target 3.5 // URP推荐最低3.5
            #pragma multi_compile _ MTOON_DEBUG_NORMAL MTOON_DEBUG_LITSHADERATE
            #pragma multi_compile _ _NORMALMAP
            #pragma multi_compile _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog
            
            #pragma vertex vert_forward_base
            #pragma fragment frag_forward

            // URP核心包含文件
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Fog.hlsl"

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_ShadeTexture);SAMPLER(sampler_ShadeTexture);
            TEXTURE2D(_BumpMap);SAMPLER(sampler_BumpMap);
            TEXTURE2D(_ReceiveShadowTexture);SAMPLER(sampler_ReceiveShadowTexture);
            TEXTURE2D(_ShadingGradeTexture);SAMPLER(sampler_ShadingGradeTexture);
            TEXTURE2D(_SphereAdd);SAMPLER(sampler_SphereAdd);
            TEXTURE2D(_EmissionMap);SAMPLER(sampler_EmissionMap);
            TEXTURE2D(_OutlineWidthTexture);SAMPLER(sampler_OutlineWidthTexture);
            // MToon核心逻辑
            CBUFFER_START(UnityPerMaterial)
            half _Cutoff;
            half4 _Color;
            half4 _ShadeColor;
            half _BumpScale;
            half _ReceiveShadowRate;
            half _ShadingGradeRate;
            half _ShadeShift;
            half _ShadeToony;
            half _LightColorAttenuation;
            half _IndirectLightIntensity;
            half4 _EmissionColor;
            half _OutlineWidth;
            half _OutlineUseSoftNormal;
            half _OutlineScaledMaxDistance;
            half4 _OutlineColor;
            half _OutlineLightingMix;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float4 color        : COLOR;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 positionWS   : TEXCOORD0;
                half3 tspace0       : TEXCOORD1; // tangent.x, bitangent.x, normal.x
                half3 tspace1       : TEXCOORD2; // tangent.y, bitangent.y, normal.y
                half3 tspace2       : TEXCOORD3; // tangent.z, bitangent.z, normal.z
                float2 uv0          : TEXCOORD4;
                half isOutline      : TEXCOORD5;
                half4 color         : TEXCOORD6;
                // LIGHTING_COORDS(7, 8) // URP阴影坐标
                // UNITY_FOG_COORDS(9)
            };

            inline Varyings InitializeVaryings(Attributes v, float4 projectedVertex, half isOutline)
            {
                Varyings o;
                o.positionHCS = projectedVertex;
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.uv0 = v.uv;

                // 计算世界空间切线空间
                half3 normalWS = TransformObjectToWorldNormal(v.normalOS);
                half3 tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);
                half tangentSign = v.tangentOS.w * GetOddNegativeScale();
                half3 bitangentWS = cross(normalWS, tangentWS) * tangentSign;
                
                o.tspace0 = half3(tangentWS.x, bitangentWS.x, normalWS.x);
                o.tspace1 = half3(tangentWS.y, bitangentWS.y, normalWS.y);
                o.tspace2 = half3(tangentWS.z, bitangentWS.z, normalWS.z);

                o.isOutline = isOutline;
                o.color = v.color;
                
                // TRANSFER_VERTEX_TO_FRAGMENT(o); // URP阴影坐标传递
                // UNITY_TRANSFER_FOG(o, o.positionHCS);
                return o;
            }

            inline float4 CalculateOutlineVertexClipPosition(Attributes v)
            {
                float4 nearUpperRight = mul(UNITY_MATRIX_I_P, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));
                float aspect = abs(nearUpperRight.y / nearUpperRight.x);
                
                half outlineTex = SAMPLE_TEXTURE2D_LOD(_OutlineWidthTexture, sampler_OutlineWidthTexture, float2(v.uv.x, v.uv.y), 0).r;
   
                #if defined(MTOON_OUTLINE_WIDTH_WORLD)
                    float3 outlineOffset = 0.01 * _OutlineWidth * outlineTex * v.normalOS;
                    float4 vertex = TransformObjectToHClip(v.positionOS + outlineOffset);
                #elif defined(MTOON_OUTLINE_WIDTH_SCREEN)
                    float4 vertex = TransformObjectToHClip(v.positionOS);
                    float3 viewNormal = TransformObjectToViewDir(v.normalOS);
                    float3 clipNormal = TransformViewToHClip(viewNormal);
                    float2 projectedNormal = normalize(clipNormal.xy);
                    projectedNormal *= min(vertex.w, _OutlineScaledMaxDistance);
                    projectedNormal.x *= aspect;
                    vertex.xy += 0.01 * _OutlineWidth * outlineTex * projectedNormal.xy;
                #elif defined(MTOON_OUTLINE_WIDTH_WORLD_VERTEX_COLOR)
                    float3 normal = lerp(v.normalOS, v.tangentOS.xyz, _OutlineUseSoftNormal);
                    float3 outlineOffset = 0.01 * v.color.x * _OutlineWidth * outlineTex * normal;
                    float4 vertex = TransformObjectToHClip(v.positionOS + outlineOffset);
                #elif defined(MTOON_OUTLINE_WIDTH_SCREEN_VERTEX_COLOR)
                    float3 normal = lerp(v.normalOS, v.tangentOS.xyz, _OutlineUseSoftNormal);
                    float4 vertex = TransformObjectToHClip(v.positionOS);
                    float3 viewNormal = TransformObjectToViewDir(normal);
                    float3 clipNormal = TransformViewToHClip(viewNormal);
                    float2 projectedNormal = normalize(clipNormal.xy);
                    projectedNormal *= min(vertex.w, _OutlineScaledMaxDistance);
                    projectedNormal.x *= aspect;
                    vertex.xy += 0.01 * v.color.x * _OutlineWidth * outlineTex * projectedNormal.xy;
                #else
                    float4 vertex = TransformObjectToHClip(v.positionOS);
                #endif
                return vertex;
            }

            half4 frag_forward(Varyings i, half facing : VFACE) : SV_TARGET
            {
                #ifdef MTOON_CLIP_IF_OUTLINE_IS_NONE
                    #ifndef MTOON_OUTLINE_WIDTH_WORLD
                    #ifndef MTOON_OUTLINE_WIDTH_SCREEN
                    #ifndef MTOON_OUTLINE_WIDTH_WORLD_VERTEX_COLOR
                    #ifndef MTOON_OUTLINE_WIDTH_SCREEN_VERTEX_COLOR
                        clip(-1);
                    #endif
                    #endif
                    #endif
                    #endif
                #endif

                // 主纹理采样
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0);
                
                // Alpha处理
                half alpha = 1;
                #ifdef _ALPHATEST_ON
                    alpha = _Color.a * mainTex.a;
                    clip(alpha - _Cutoff);
                #endif
                #ifdef _ALPHABLEND_ON
                    alpha = _Color.a * mainTex.a;
                #endif
                
                // 法线处理
                half3 normalWS;
                #ifdef _NORMALMAP
                    half3 tangentNormal = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.uv0), _BumpScale);
                    normalWS.x = dot(i.tspace0, tangentNormal);
                    normalWS.y = dot(i.tspace1, tangentNormal);
                    normalWS.z = dot(i.tspace2, tangentNormal);
                #else
                    normalWS = half3(i.tspace0.z, i.tspace1.z, i.tspace2.z);
                #endif
                normalWS *= facing;
                normalWS *= lerp(1.0, -1.0, i.isOutline);
                normalWS = normalize(normalWS);

                // 光照计算
                Light mainLight = GetMainLight(); // URP主光源获取
                half3 lightDirWS = normalize(mainLight.direction);
                half receiveShadow = _ReceiveShadowRate * SAMPLE_TEXTURE2D(_ReceiveShadowTexture, sampler_ReceiveShadowTexture, i.uv0).a;
                half shadingGrade = 1.0 - _ShadingGradeRate * (1.0 - SAMPLE_TEXTURE2D(_ShadingGradeTexture, sampler_ShadingGradeTexture, i.uv0).r);
                half shadowAtten = mainLight.shadowAttenuation;

                
                half lightIntensity = dot(lightDirWS, normalWS);
                return shadowAtten * lightIntensity;
                
                lightIntensity = lightIntensity * 0.5 + 0.5; // [-1,1] -> [0,1]
                lightIntensity = lightIntensity * (1.0 - receiveShadow * (1.0 - (shadowAtten * 0.5 + 0.5))); // 阴影接收
                lightIntensity = lightIntensity * shadingGrade; // 明暗等级
                lightIntensity = lightIntensity * 2.0 - 1.0; // [0,1] -> [-1,1]
                lightIntensity = smoothstep(_ShadeShift, _ShadeShift + (1.0 - _ShadeToony), lightIntensity); // 卡通明暗

                // 颜色光照计算
                half3 directLighting = lightIntensity * mainLight.color.rgb;
                half3 indirectLighting = _IndirectLightIntensity * SampleSH(normalWS); // URP环境光采样
                half3 lighting = directLighting + indirectLighting;
                lighting = lerp(lighting, max(0.001, max(lighting.x, max(lighting.y, lighting.z))), _LightColorAttenuation);
                
                // 亮部/暗部颜色插值
                half4 shade = _ShadeColor * SAMPLE_TEXTURE2D(_ShadeTexture, sampler_ShadeTexture, i.uv0);
                half4 lit = _Color * mainTex;
                half3 col;
                #ifdef MTOON_FORWARD_ADD
                    col = lerp(half3(0,0,0), saturate(lit.rgb - shade.rgb), lighting);
                #else
                    col = lerp(shade.rgb, lit.rgb, lighting);
                #endif

                // MatCap添加光
                // #ifndef MTOON_FORWARD_ADD
                //     half3 cameraUpWS = normalize(GetCameraUpWS());
                //     half3 viewDirWS = normalize(GetCameraPositionWS() - i.positionWS.xyz);
                //     half3 viewUpWS = normalize(cameraUpWS - viewDirWS * dot(viewDirWS, cameraUpWS));
                //     half3 viewRightWS = normalize(cross(viewDirWS, viewUpWS));
                //     half2 rimUv = half2(dot(viewRightWS, normalWS), dot(viewUpWS, normalWS)) * 0.5 + 0.5;
                //     half3 rimLighting = SAMPLE_TEXTURE2D(_SphereAdd, sampler_SphereAdd, rimUv);
                //     col += lerp(rimLighting, half3(0, 0, 0), i.isOutline);
                // #endif

                // 自发光
                #ifndef MTOON_FORWARD_ADD
                    half3 emission = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, i.uv0).rgb * _EmissionColor.rgb;
                    col += lerp(emission, half3(0, 0, 0), i.isOutline);
                #endif

                // 轮廓线颜色
                #ifdef MTOON_OUTLINE_COLOR_FIXED
                    col = lerp(col, _OutlineColor.rgb, i.isOutline);
                #elif MTOON_OUTLINE_COLOR_MIXED
                    col = lerp(col, _OutlineColor.rgb * lerp(half3(1, 1, 1), col, _OutlineLightingMix), i.isOutline);
                #endif

                // 调试模式
                #ifdef MTOON_DEBUG_NORMAL
                    #ifdef MTOON_FORWARD_ADD
                        return half4(0, 0, 0, 0);
                    #else
                        return half4(normalWS * 0.5 + 0.5, alpha);
                    #endif
                #elif MTOON_DEBUG_LITSHADERATE
                    #ifdef MTOON_FORWARD_ADD
                        return half4(0, 0, 0, 0);
                    #else
                        return half4(lighting, alpha);
                    #endif
                #endif

                // 雾效应用
                half4 result = half4(col, alpha);

                return result;
            }

            // 顶点着色器 - 主渲染
            Varyings vert_forward_base(Attributes v)
            {
                v.normalOS = normalize(v.normalOS);
                return InitializeVaryings(v, TransformObjectToHClip(v.positionOS), 0);
            }

            // 顶点着色器 - 轮廓线
            Varyings vert_forward_base_outline(Attributes v)
            {
                v.normalOS = normalize(v.normalOS);
                return InitializeVaryings(v, CalculateOutlineVertexClipPosition(v), 1);
            }

            // 顶点着色器 - 附加光源
            Varyings vert_forward_add(Attributes v)
            {
                v.normalOS = normalize(v.normalOS);
                return InitializeVaryings(v, TransformObjectToHClip(v.positionOS), 0);
            }
            ENDHLSL
        }
        // 阴影投射Pass (URP版本)
        UsePass "Universal Render Pipeline/Lit/SHADOWCASTER"
    }
    
    Fallback "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "MToon.MToonInspector"
}