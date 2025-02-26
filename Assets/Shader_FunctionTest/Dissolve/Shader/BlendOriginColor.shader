Shader "Art_URP/FunctionTest/TwoEdgeColor"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
        _NoiseTex ("Noise Tex", 2D) = "white" { }
        _Threshold ("Threshold", Range(0, 1)) = 0
        _EdgeLength("EdgeLength" , Range(0.0 , 0.2)) = 0.1
        _EdgeFirstColor("EdgeColor" , Color) = (1,1,1,1)
        _EdgeSecondColor("EdgeSecondColor" , Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Tags{"RenderPipeline" = "UniversalPipeline"}
            Cull off

            // #define _ALPHATEST_ON 1

            HLSLPROGRAM

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float4 uv          : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);   SAMPLER(sampler_NoiseTex);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _NoiseTex_ST;
                float  _Threshold;
                float  _EdgeLength;
                float4 _EdgeFirstColor;
                float4 _EdgeSecondColor;
            CBUFFER_END
           
            Varyings vert (Attributes v)
            {
                UNITY_SETUP_INSTANCE_ID(v);

                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv.xy = TRANSFORM_TEX(v.texcoord , _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord , _NoiseTex);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                // UNITY_SETUP_INSTANCE_ID(i);

                half4 FinalColor;

                half noiseMap = SAMPLE_TEXTURE2D(_NoiseTex , sampler_NoiseTex , i.uv.zw).r;
                clip(noiseMap - _Threshold);
                
                half  degree = saturate((noiseMap - _Threshold) / _EdgeLength);
                half4 edgeColor = lerp(_EdgeFirstColor, _EdgeSecondColor, degree);

                half4 mainMap = SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , i.uv.xy);
            
                FinalColor = half4(lerp(edgeColor , mainMap , degree).rgb , 1.0);
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
