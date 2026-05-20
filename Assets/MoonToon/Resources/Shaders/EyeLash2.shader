Shader "Unlit/EyeLash2_URP"
{
    Properties
    {
        _GlossRange ("GlossRange", Range(0, 1)) = 1
        _GlossIntensity ("GlossIntensity", Range(0, 2)) = 1
        _FresnelRange ("FresnelRange", Range(0, 10)) = 0
        _FresnelColor ("FresnelColor", Color) = (1,1,1,1)
        _Alpha ("Alpha", Range(1, 10)) = 1
        _EyeTexture ("EyeTexture", 2D) = "white" {}
        _GlossColor ("GlossColor", Color) = (0.5,0.5,0.5,1)
        _GlossMask ("GlossMask", 2D) = "white" {}
        _CubeMap ("CubeMap", Cube) = "_Skybox" {}
        _CubeMapIntensity ("CubeMapIntensity", Range(0, 1)) = 0
        _Angle ("Angle", Range(0, 360)) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderPipeline"="UniversalPipeline"
        }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                //UNITY_FOG_COORDS(3)
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            TEXTURE2D(_EyeTexture); SAMPLER(sampler_EyeTexture);
            TEXTURE2D(_GlossMask); SAMPLER(sampler_GlossMask);
            TEXTURECUBE(_CubeMap); SAMPLER(sampler_CubeMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _EyeTexture_ST;
                float4 _GlossMask_ST;
                half _GlossRange;
                half _GlossIntensity;
                half _FresnelRange;
                half4 _FresnelColor;
                half _Alpha;
                half4 _GlossColor;
                half _CubeMapIntensity;
                half _Angle;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                output.positionWS = TransformObjectToWorld(input.vertex.xyz);
                output.positionHCS = TransformWorldToHClip(output.positionWS);
                output.uv = TRANSFORM_TEX(input.uv, _EyeTexture);
                output.normalWS = TransformObjectToWorldNormal(input.normal);

                //UNITY_TRANSFER_FOG(output, output.positionHCS);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                float2 uv = input.uv;
                float3 positionWS = input.positionWS;
                float3 normalWS = normalize(input.normalWS);
                float3 viewDirWS = normalize(GetWorldSpaceViewDir(positionWS));
                float3 reflectDir = reflect(-viewDirWS, normalWS);

                // 主光源
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);
                float3 halfDir = normalize(viewDirWS + lightDir);

                // UV 旋转（高光遮罩）
                half viewXPi = ((_Angle + (viewDirWS.r * 20.0)) * 0.005555556 * PI);
                half s = sin(viewXPi);
                half c = cos(viewXPi);
                half2 uvRot = mul(uv - 0.5, float2x2(c, -s, s, c)) + 0.5;

                // 采样
                half4 eyeTex = SAMPLE_TEXTURE2D(_EyeTexture, sampler_EyeTexture, uv);
                half4 glossMask = SAMPLE_TEXTURE2D(_GlossMask, sampler_GlossMask, uvRot);
                half3 cubemap = SAMPLE_TEXTURECUBE(_CubeMap, sampler_CubeMap, reflectDir).rgb;

                // 高光
                half specPow = exp2(_GlossRange * 10.0 + 1.0);
                half spec = pow(max(0, dot(normalWS, halfDir)), specPow);
                half3 specCol = spec * _GlossIntensity * _GlossColor.rgb * glossMask.r;

                // 菲涅尔
                half fresnel = pow(1.0 - max(0, dot(normalWS, viewDirWS)), _FresnelRange);
                half3 fresnelCol = fresnel * _FresnelColor.rgb;

                // 最终颜色
                half3 baseColor = eyeTex.rgb + cubemap * _CubeMapIntensity;
                half3 finalRGB = baseColor + specCol + fresnelCol;
                half finalAlpha = eyeTex.a + (specCol.b + fresnelCol.b) * _Alpha;
                half4 finalColor = half4(finalRGB, finalAlpha);

                //UNITY_APPLY_FOG(input.fogCoord, finalColor);
                return finalColor;
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}