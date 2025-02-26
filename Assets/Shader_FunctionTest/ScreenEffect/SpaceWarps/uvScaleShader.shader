Shader "Art_URP/FunctionTest/uvScaleShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_DistorValue ("_DistorValue",Range(0,1)) = 1.0
	}
	SubShader
	{
		Tags{"RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" }
		LOD 100

		Pass
		{
			Tags{"LightMode" = "UniversalForward"}
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct Attributes
			{
				float4 positionOS	: POSITION;
				float2 texcoord		: TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionHCS : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
				float _DistorValue;
			CBUFFER_END
			
			Varyings vert (Attributes v)
			{
				Varyings o;
				o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				
				return o;
			}
			
			half4 frag (Varyings i) : SV_Target
			{
				float2 distorCenter = float2(0.5,0.5);
				float2 dir = i.uv - distorCenter.xy;					//偏移方向

				// float2 offset = sin(_Time.y*0.5) * normalize(dir) * (1 - length(dir));
				float2 offset = _DistorValue * normalize(dir) * (1 - length(dir));

				half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv+offset);
				
				return col;
			}
			ENDHLSL
		}
	}
}
