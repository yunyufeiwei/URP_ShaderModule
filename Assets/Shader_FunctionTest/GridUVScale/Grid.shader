Shader "Art_URP/FunctionTest/Grid"
{
	Properties
	{
		_Color("Color" , Color) = (1,1,1,1)
		_Thickness("Thickness", Float) = 0.95
		_GridSize("GridSize", Float) = 1
		[HideInInspector]_GridCount("GridCount", Float) = 1
	}

	SubShader
	{
		Tags { "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" "RenderType"="Opaque" }
		
		Pass
		{
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"

			struct Attribute
			{
				float4 positionOS	: POSITION;
				float3 normalOS		: NORMAL;
				float4 texcoord		: TEXCOORD0;
			};

			struct Varying
			{
				float4 positionHCS	: SV_POSITION;
				float2 uv			: TEXCOORD3;
			};

			CBUFFER_START(UnityPerMaterial)
				float4 _Color;
				float  _GridSize;
				float _GridCount;
				float _Thickness;
			CBUFFER_END
			
			Varying vert( Attribute v)
			{
				Varying o = (Varying)0;
				o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
				o.uv = v.texcoord.xy;
				return o;
			}
			
			half4 frag ( Varying i) : SV_Target
			{
				half4 FinalColor;
				
				float3 objectScale = float3( length( GetObjectToWorldMatrix()[ 0 ].xyz ), length( GetObjectToWorldMatrix()[ 1 ].xyz ), length( GetObjectToWorldMatrix()[ 2 ].xyz ) );
				float2 appendVector = (float2(objectScale.x , objectScale.z));
				float2 gridUV = (( float2(0.5,0.5) - i.uv )*( ( (appendVector).xy * 10 * (1/_GridSize) ) * _GridCount ).x + 0.0);
				float3 grid = (max( step(0.0 , (abs(((frac(gridUV.x) * 2.0 ) - 1.0)) - (1- _Thickness))) , step(0.0 , (abs((( frac( gridUV.y) * 2.0) - 1.0)) - (1 - _Thickness))))).xxx;

				float3 diffuseColor = grid * _Color.rgb;
				
				clip(grid.r - 0.01);
				FinalColor = half4(diffuseColor , 1.0);
				
				return FinalColor;
			}
			ENDHLSL
		}
	}
Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
