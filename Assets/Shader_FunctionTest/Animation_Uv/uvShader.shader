Shader "Art_URP/FunctionTest/uvShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_rippleTex ("rippleTex", 2D) = "white" {}
		_Offset("Offset",Vector) = (0.25,0.25,0,0)
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
				float4 positionHCS	: SV_POSITION;
				float2 uv			: TEXCOORD0;
			};

			TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
			TEXTURE2D(_rippleTex);SAMPLER(sampler_rippleTex);
			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
				float4 _Offset;
			CBUFFER_END
			
			Varyings vert (Attributes v)
			{
				Varyings o = (Varyings)0;
				o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}
			
			half4 frag (Varyings i) : SV_Target
			{
				float2 uv_offset = float2(0,0);
				uv_offset.x = _Time.y * _Offset.x;
				uv_offset.y = _Time.y * _Offset.y;

				// sample the texture
				half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv);
				half4 rippleCol = SAMPLE_TEXTURE2D(_rippleTex, sampler_rippleTex , i.uv + uv_offset);
				
				return col+rippleCol;
			}
			ENDHLSL
		}
	}
}
