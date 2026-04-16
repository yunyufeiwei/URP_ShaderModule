Shader "Custom/GrabTransparentPlane"
{
    Properties
    {
        _Tint ("Tint", Color) = (1, 1, 1, 0.5)
        _BlurSize ("BlurStrength", Range(0, 10)) = 3.0
        _Alpha ("Alpha", Range(0, 1)) = 0.8
        _Iterations ("InterationCounts", Range(1, 8)) = 3
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Transparent+500"
            "RenderType" = "Transparent"
        }

        Pass
        {
            Name "GaussianBlur"
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Back

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_GrabTransparentTex);SAMPLER(sampler_GrabTransparentTex);
            float4 _GrabTransparentTex_TexelSize;

            CBUFFER_START(UnityPerMaterial)
                half4 _Tint;
                float _BlurSize;
                float _Alpha;
                float _Iterations;
            CBUFFER_END

            // 高斯权重 (9-tap: 1 4 6 4 1 归一化)
            static const float weights[5] = { 0.0625, 0.25, 0.375, 0.25, 0.0625 };
            static const float offsets[5] = { -2.0, -1.0, 0.0, 1.0, 2.0 };

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 screenPos  : TEXCOORD0;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.screenPos = ComputeScreenPos(output.positionCS);
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                float2 screenUV = input.screenPos.xy / input.screenPos.w;
                int iterations = max((int)_Iterations, 1);

                half3 color = half3(0, 0, 0);

                // 多次迭代，每次迭代扩大采样范围，叠加模糊效果
                for (int iter = 0; iter < iterations; iter++)
                {
                    float scale = 1.0 + float(iter);

                    // 水平方向
                    for (int i = 0; i < 5; i++)
                    {
                        float2 offset = float2(offsets[i] * _BlurSize * scale * _GrabTransparentTex_TexelSize.x, 0);
                        color += SAMPLE_TEXTURE2D(_GrabTransparentTex, sampler_GrabTransparentTex, screenUV + offset).rgb * weights[i];
                    }

                    // 垂直方向
                    for (int j = 0; j < 5; j++)
                    {
                        float2 offset = float2(0, offsets[j] * _BlurSize * scale * _GrabTransparentTex_TexelSize.y);
                        color += SAMPLE_TEXTURE2D(_GrabTransparentTex, sampler_GrabTransparentTex, screenUV + offset).rgb * weights[j];
                    }
                }

                // 水平+垂直各采样了 iterations 次，总共 2*iterations 组
                color /= float(iterations * 2);

                color *= _Tint.rgb;
                return half4(color, _Alpha);
            }
            ENDHLSL
        }
    }
}
