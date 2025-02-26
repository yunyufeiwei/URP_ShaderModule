Shader "Art_URP/FunctionTest/DissolveFromDirectionX"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
        _NoiseTex ("Noise Tex", 2D) = "white" { }
        _Threshold ("Threshold", Range(0, 1)) = 0
        _EdgeLength ("Edge Length", Range(0.0, 0.2)) = 0.1
        _RampTex ("Ramp Tex", 2D) = "white" { }
        _Direction ("Direction--(1表示了X的正方向)", Int) = 1 //1表示从X正方向开始，其他值则从负方向
        _MinBorderX ("Min Border X", Float) = -0.5 //从程序传入
        _MaxBorderX ("Max Border X", Float) = 0.5  //从程序传入
        _DistanceEffect ("Distance Effect", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        LOD 100

        pass
        {
            Tags{"RenderPipeline" = "UniversalPipeline"}
            Cull off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
                float3 normal       : NORMAL;
            };

            struct Varyings
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 positionHCS  : SV_POSITION;
                float4 uv           : TEXCOORD0;
                float3 objPositionX : TEXCOORD1;
            };

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);   SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_RampTex);   SAMPLER(sampler_RampTex);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _NoiseTex_ST;
                float  _Threshold;
                float  _EdgeLength;
                float  _Direction;
                float  _MinBorderX;
                float  _MaxBorderX;
                float  _DistanceEffect;
            CBUFFER_END
           
            Varyings vert (Attributes v)
            {
                UNITY_SETUP_INSTANCE_ID(v);

                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv.xy = TRANSFORM_TEX(v.texcoord , _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord , _NoiseTex);

                o.objPositionX = v.positionOS.x;
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                half4 FinalColor;
                half range = _MaxBorderX - _MinBorderX;
                half border = _MinBorderX;
                if(_Direction == 1) //1表示从x正方向开始，其它值则从负方向
                {
                    border = _MaxBorderX;
                }

                half distance = abs(i.objPositionX - border);
                half normalizeDistance = saturate(distance/range);

                half noiseMap = SAMPLE_TEXTURE2D(_NoiseTex , sampler_NoiseTex , i.uv.zw).r * (1 - _DistanceEffect) + normalizeDistance * _DistanceEffect;
                clip(noiseMap - _Threshold);
                
                half  degree = saturate((noiseMap - _Threshold) / _EdgeLength);
                half4 edgeColor = SAMPLE_TEXTURE2D(_RampTex , sampler_RampTex , half2(degree,degree));  //使用noise贴图的黑白作为RampTex的uv来采样

                half4 mainMap = SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , i.uv.xy);

                FinalColor = half4(lerp(edgeColor , mainMap, degree).rgb , 1.0);
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
