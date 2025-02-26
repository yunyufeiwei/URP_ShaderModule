Shader "Art_URP/FunctionTest/vertexAndUvAnim" 
{
	Properties 
	{
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Speed ("Speed", Float) = 0.5
		_MaskMap("MaskMap",2D) = "black"{}
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
				float2 uv1			: TEXCOORD1;
				float4 ffff			: TEXCOORD2;
			};

			TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
			TEXTURE2D(_MaskMap);SAMPLER(sampler_MaskMap);
			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
				float4 _MaskMap_ST;
				float _Speed;
			CBUFFER_END

			Varyings vert(Attributes v)
			{
				Varyings o = (Varyings)0;
				float dist = distance(v.positionOS.xyz, float3(0,0,0));		//float3(0,0,0)表示的是该模型的轴心点

				//想要在顶点阶段通过纹理控制顶点偏移，需要使用SAMPLE_TEXTURE2D_LOD，常规的纹理采样做不到
				o.uv1 = TRANSFORM_TEX(v.texcoord , _MaskMap);
				// o.ffff =SAMPLE_TEXTURE2D(_MaskMap,sampler_MaskMap,o.uv1);
				o.ffff =SAMPLE_TEXTURE2D_LOD(_MaskMap,sampler_MaskMap,o.uv1,1);
				
				float h = sin(dist * 2 + _Time.z) /2 * o.ffff;
				v.positionOS.y = h;
				o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
			
				o.uv = TRANSFORM_TEX(v.texcoord , _MainTex);
				o.uv +=  float2( _Time.y * _Speed , 0.0);
			
			return o;
			};

			half4 frag(Varyings i):SV_TARGET
			{
				half4 col = SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , i.uv);
				return col;
			};
			ENDHLSL
		}
	}
}
