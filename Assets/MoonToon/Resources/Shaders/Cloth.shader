Shader "Unlit/Cloth_URP"
{
    Properties
    {
        _MainColor ("MainColor", Color) = (1,1,1,1)
        _MainTexture ("MainTexture", 2D) = "white" {}
        _MainNormal ("MainNormal", 2D) = "bump" {}
        _GlossColor ("GlossColor", Color) = (0.5,0.5,0.5,1)
        _Gloss ("Gloss", Range(0, 1)) = 0.45
        _Alpha ("Alpha", Range(0, 1)) = 1

        [Header(AboutUV2)]
        _UV2Color ("UV2Color", Color) = (1,1,1,1)
        _UV2Texture ("UV2Texture", 2D) = "white" {}
        _UV2Normals ("UV2Normals", 2D) = "bump" {}
        _UV3Color ("UV3Color", Color) = (0.5,0.5,0.5,1)
        _UV3Texture ("UV3Texture", 2D) = "black" {}
        _UV3Normal ("UV3Normal", 2D) = "bump" {}
        _UV2GlossColor ("UV2GlossColor", Color) = (0.5,0.5,0.5,1)
        _UV2Gloss ("UV2Gloss", Range(0, 1)) = 0.45
        _HuawenAlpha ("HuawenAlpha", Range(0, 1)) = 1

        _ClipMask("ClipMask",2D) = "white"{}
        _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "Queue"="Geometry"
            "IgnoreProjector"="True"
            "RenderPipeline"="UniversalPipeline"
        }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            Cull Off
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 uv0          : TEXCOORD0;
                float2 uv1          : TEXCOORD1;
                float2 uv2          : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float2 uv1          : TEXCOORD1;
                float2 uv2          : TEXCOORD2;
                float3 positionWS   : TEXCOORD3;
                float3 normalWS     : TEXCOORD4;
                float3 tangentWS    : TEXCOORD5;
                float3 bitangentWS  : TEXCOORD6;
                float3 viewDirWS    : TEXCOORD7;
                //UNITY_FOG_COORDS(8)
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            TEXTURE2D(_MainTexture); SAMPLER(sampler_MainTexture);
            TEXTURE2D(_MainNormal); SAMPLER(sampler_MainNormal);
            TEXTURE2D(_UV2Texture); SAMPLER(sampler_UV2Texture);
            TEXTURE2D(_UV2Normals); SAMPLER(sampler_UV2Normals);
            TEXTURE2D(_UV3Texture); SAMPLER(sampler_UV3Texture);
            TEXTURE2D(_UV3Normal); SAMPLER(sampler_UV3Normal);
            TEXTURE2D(_ClipMask); SAMPLER(sampler_ClipMask);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTexture_ST;
                float4 _MainNormal_ST;
                float4 _UV2Texture_ST;
                float4 _UV2Normals_ST;
                float4 _UV3Texture_ST;
                float4 _UV3Normal_ST;
                float4 _ClipMask_ST;

                float4 _MainColor;
                float4 _GlossColor;
                float _Gloss;
                float _Alpha;

                float4 _UV2Color;
                float4 _UV2GlossColor;
                float _UV2Gloss;
                float4 _UV3Color;
                float _HuawenAlpha;

                float _Cutoff;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionHCS = TransformWorldToHClip(output.positionWS);
                output.uv = TRANSFORM_TEX(input.uv0, _MainTexture);
                output.uv1 = input.uv1;
                output.uv2 = input.uv2;

                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.tangentWS = TransformObjectToWorldDir(input.tangentOS.xyz);
                output.bitangentWS = cross(output.normalWS, output.tangentWS) * input.tangentOS.w;
                output.viewDirWS = GetWorldSpaceViewDir(output.positionWS);

                //UNITY_TRANSFER_FOG(output, output.positionHCS);
                return output;
            }

            half4 frag(Varyings input, float facing : VFACE) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                float faceSign = facing >= 0 ? 1.0 : -1.0;
                float2 uv = input.uv;
                float2 uv1 = input.uv1;
                float2 uv2 = input.uv2;

                float3 positionWS = input.positionWS;
                float3 viewDirWS = normalize(input.viewDirWS);
                float3 normalWS = normalize(input.normalWS) * faceSign;
                float3 tangentWS = normalize(input.tangentWS);
                float3 bitangentWS = normalize(input.bitangentWS);
                float3x3 TBN = float3x3(tangentWS, bitangentWS, normalWS);

                // 采样纹理
                float4 mainTex = SAMPLE_TEXTURE2D(_MainTexture, sampler_MainTexture, uv);
                float4 uv2Tex = SAMPLE_TEXTURE2D(_UV2Texture, sampler_UV2Texture, uv1);
                float4 uv3Tex = SAMPLE_TEXTURE2D(_UV3Texture, sampler_UV3Texture, uv2);
                float4 clipMask = SAMPLE_TEXTURE2D(_ClipMask, sampler_ClipMask, uv1);

                float3 nMain = UnpackNormal(SAMPLE_TEXTURE2D(_MainNormal, sampler_MainNormal, uv));
                float3 nUV2 = UnpackNormal(SAMPLE_TEXTURE2D(_UV2Normals, sampler_UV2Normals, uv1));
                float3 nUV3 = UnpackNormal(SAMPLE_TEXTURE2D(_UV3Normal, sampler_UV3Normal, uv2));

                // UV 混合逻辑
                float uv2Alpha = uv2Tex.a;
                float uvAlpha = saturate(uv3Tex.a + uv2Alpha);
                float3 finalN = lerp(nMain, lerp(nUV3, nUV2, uv2Alpha), uvAlpha);
                float3 N = normalize(mul(finalN, TBN));

                // 颜色混合
                float3 mainCol = mainTex.rgb * _MainColor.rgb;
                float3 uv3Col = uv3Tex.rgb * _UV3Color.rgb;
                float3 uv2Col = uv2Tex.rgb * _UV2Color.rgb;
                float3 patternCol = lerp(uv3Col, uv2Col, uv2Alpha);
                float3 baseCol = lerp(mainCol, patternCol, uvAlpha);

                // 透明度混合
                float finalAlpha = lerp(_Alpha, _HuawenAlpha, uvAlpha);
                clip(clipMask.r - _Cutoff);

                float3 finalColor = 0.0;

                // 主光源
                Light mainLight = GetMainLight();
                float3 L = normalize(mainLight.direction);
                float3 H = normalize(L + viewDirWS);
                half nl = saturate(dot(L, N)) * 0.5 + 0.5;

                float specPow = exp2(_Gloss * 10.0 + 1.0);
                float uv2SpecPow = exp2(_UV2Gloss * 10.0 + 1.0);
                float spec = pow(max(0, dot(N, H)), specPow);
                float uv2Spec = pow(max(0, dot(N, H)), uv2SpecPow);
                float3 specCol = lerp(spec * _GlossColor.rgb, uv2Spec * _UV2GlossColor.rgb, uvAlpha);

                finalColor += (baseCol * nl + specCol + UNITY_LIGHTMODEL_AMBIENT.rgb) * mainLight.color;

                // 额外多光源
                int addLightCount = GetAdditionalLightsCount();
                for (int i = 0; i < addLightCount; i++)
                {
                    Light light = GetAdditionalLight(i, positionWS);
                    float3 L_add = normalize(light.direction);
                    float3 H_add = normalize(L_add + viewDirWS);
                    half nl_add = saturate(dot(L_add, N)) * 0.5 + 0.5;

                    float spec_add = pow(max(0, dot(N, H_add)), specPow);
                    float uv2Spec_add = pow(max(0, dot(N, H_add)), uv2SpecPow);
                    float3 specCol_add = lerp(spec_add * _GlossColor.rgb, uv2Spec_add * _UV2GlossColor.rgb, uvAlpha);

                    finalColor += (baseCol * nl_add + specCol_add) * light.color * light.distanceAttenuation;
                }

                half4 finalRGBA = half4(finalColor, finalAlpha);
                //UNITY_APPLY_FOG(input.fogCoord, finalRGBA);
                return finalRGBA;
            }
            ENDHLSL
        }

        // 阴影投射
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }

            ZWrite On
            ZTest LEqual
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct Attributes { float4 positionOS : POSITION; };
            struct Varyings { float4 positionHCS : SV_POSITION; };

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionHCS = TransformWorldToHClip(
                    ApplyShadowBias(input.positionOS.xyz, float3(0,1,0), 0.0)
                );
                return output;
            }

            half4 frag(Varyings input) : SV_Target { return 0; }
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}