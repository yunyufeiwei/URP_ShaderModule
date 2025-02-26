Shader "Art_URP/FunctionTest/DissolveFrontPoint"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
        _NoiseTex ("Noise Tex", 2D) = "white" { }
        _Threshold ("Threshold", Range(0, 1)) = 0
        _EdgeLength("EdgeLength" , Range(0.0 , 0.2)) = 0.1
        _RampTex("RampTex",2D) = "white"{}

        _StartPoint("StartPoint",vector) = (1,1,1,1)
        _MaxDistance("MaxDistance",float) = 0
        _DistanceEffect("DistanceEffect" , Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Tags{"RenderPipeline" = "UniversalPipeline"}
            Cull off

            HLSLPROGRAM

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 positionHCS  : SV_POSITION;
                float4 uv           : TEXCOORD0;
                float3 objPos       : TEXCOORD1;
                float3 objStartPos  : TEXCOORD2;
            };

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);   SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_RampTex);   SAMPLER(sampler_RampTex);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _NoiseTex_ST;
                float  _Threshold;
                float  _EdgeLength;

                float4 _StartPoint;
                float  _MaxDistance;
                float  _DistanceEffect;
            CBUFFER_END
           
            Varyings vert (Attributes v)
            {
                UNITY_SETUP_INSTANCE_ID(v);

                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv.xy = TRANSFORM_TEX(v.texcoord , _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord , _NoiseTex);

                o.objPos = v.positionOS.xyz;
                o.objStartPos = TransformWorldToObject(_StartPoint.xyz);        //将开始点的坐标从世界空间转换到模型空间
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                // UNITY_SETUP_INSTANCE_ID(i);

                half4 FinalColor;

                half distance = length(i.objPos - i.objStartPos);
                half normalizeDistance = saturate(distance/_MaxDistance);

                half noiseMap = SAMPLE_TEXTURE2D(_NoiseTex , sampler_NoiseTex , i.uv.zw).r * (1 - _DistanceEffect) + normalizeDistance * _DistanceEffect;
                clip(noiseMap - _Threshold);
                
                half  degree = saturate((noiseMap - _Threshold) / _EdgeLength);
                half4 edgeColor = SAMPLE_TEXTURE2D(_RampTex , sampler_RampTex , half2(degree,degree));  //使用noise贴图的黑白作为RampTex的uv来采样

                half4 mainMap = SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , i.uv.xy);
            
                FinalColor = half4(lerp(edgeColor , mainMap , degree).rgb , 1.0);
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
