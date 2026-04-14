Shader "CustomPostProcess/RadialBlur"
{
    Properties
    {
        [HideInInspector]_MainTex ("Main Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "RadialBlur"
            ZTest Always
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            

            // 径向模糊参数
            float _BlurStrength;    // 模糊强度
            int   _Iterations;     // 采样次数

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                float2 center = float2(0.5, 0.5);
                float2 dir = input.uv - center;

                half4 color = half4(0, 0, 0, 0);
                int iterations = max(_Iterations, 1);

                for (int i = 0; i < iterations; i++)
                {
                    float scale = 1.0 - _BlurStrength * (float(i) / float(iterations));
                    float2 sampleUV = center + dir * scale;
                    color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, sampleUV);
                }

                color /= float(iterations);
                return color;
            }
            ENDHLSL
        }
    }
}
