Shader "Art_URP/FunctionTest/wave"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _waveLeng ("wavelenth", Range(0, 100)) = 10
        _swing ("swing", Range(0, 1)) = 0.5
        _waveRange ("waveRange", Range(0, 1)) = 0.2
        _smooth ("smooth", Range(0, 1)) = 0.2
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" }
        // No culling or depth
        Cull Off 
        ZWrite On
        ZTest Always

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

			TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
			CBUFFER_START(UnityPerMaterial)
                float _waveLeng;
                float _waveRange;
                float _swing;
                float _smooth;
			CBUFFER_END
            
            static float2 center = float2(0.5, 0.5);

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.texcoord;
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                float len = distance(center, i.uv);

                if(len > _waveRange){
                    _swing = 0;
                }
                float swing = smoothstep(len, len + _smooth, _waveRange) * _swing;

                i.uv.y += sin(len * PI * _waveLeng) * swing;

                half4 col = SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , i.uv);
                return col;
            }
            ENDHLSL
        }
    }
}
