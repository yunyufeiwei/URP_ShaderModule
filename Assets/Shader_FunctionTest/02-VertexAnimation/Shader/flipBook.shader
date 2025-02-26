Shader "Art_URP/FunctionTest/flipBook" {
	Properties 
	{
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex("MainTex",2D)="White"{}
		_SecTex("SecTex",2D)="White"{}
		_Angle("Angle",Range(0,180))=0
		_WaveLength("WaveLength",Range(0,1))=0
	}
	SubShader
	{
		Tags{"RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" }
		
		pass
		{
			Tags{"LightMode" = "UniversalForward"}
			Cull Back
			
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
            };
            
			struct Varyings 
			{
				float4 positionHCS	: POSITION;
				float2 uv			: TEXCOORD0;
			};
            
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            CBUFFER_START(UnityPerMaterial)
	            float4 _MainTex_ST;
	            half4 _Color;
				float _Angle;
			float _WaveLength;
            CBUFFER_END
            
			Varyings vert(Attributes v)
			{
				Varyings o = (Varyings)0;
				v.positionOS += float4(5,0,0,0);
				float s;
				float c;
				sincos(radians(-_Angle),s,c);
				float4x4 rotate={			
					c,s,0,0,
					-s,c,0,0,
					0,0,1,0,
					0,0,0,1
				};
				float rangeF=-s;
				v.positionOS.y = sin(v.positionOS.x*_WaveLength)*rangeF;
				v.positionOS = mul(rotate,v.positionOS);
				v.positionOS += float4(-5,0,0,0);
            	
				o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);

            	o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
				return o;
			}

			half4 frag(Varyings i):COLOR
			{
				half4 color = SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , -i.uv);
				return _Color * color;
			}
			ENDHLSL
		}

		pass
		{
			Tags{"LightMode" = "SRPDefaultUnlit"}
			Cull Front

			 HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
            };
            
			struct Varyings 
			{
				float4 pos : POSITION;
				float2 uv : TEXCOORD0;
			};

            TEXTURE2D(_SecTex);SAMPLER(sampler_SecTex);
            CBUFFER_START(UnityPerMaterial)
	            float4 _SecTex_ST;
				half4 _Color;
				float _Angle;
				float _WaveLength;
			CBUFFER_END
            
			Varyings vert(Attributes v)
			{
				Varyings o;
				v.positionOS += float4(5,0,0,0);
				float s;
				float c;
				sincos(radians(-_Angle),s,c);
				float4x4 rotate =
				{			
					c,s,0,0,
					-s,c,0,0,
					0,0,1,0,
					0,0,0,1
				};
				float rangeF=-s;

				v.positionOS.y = sin(v.positionOS.x*_WaveLength)*rangeF;
				
				v.positionOS = mul(rotate,v.positionOS);
				
				v.positionOS += float4(-5,0,0,0);
				o.pos = TransformObjectToHClip(v.positionOS.xyz);
				o.uv = TRANSFORM_TEX(v.texcoord,_SecTex);
				return o;
			}

			half4 frag(Varyings i):COLOR
			{
				float2 uv = i.uv;
				uv.x = -uv.x;
				half4 color = SAMPLE_TEXTURE2D(_SecTex , sampler_SecTex ,-uv);
				return _Color * color;
			}
			ENDHLSL
		}
	}
}
