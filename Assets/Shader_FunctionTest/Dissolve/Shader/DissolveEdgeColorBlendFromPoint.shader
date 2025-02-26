Shader "Art_URP/FunctionTest/DissolveEdgeColorBlendFromPoint"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" { }
		_Specular ("_Specular Color", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8, 200)) = 10
		_NoiseTex ("Noise", 2D) = "white" { }
		_Threshold ("Threshold", Range(0.0, 1.0)) = 0.5
		_EdgeLength ("Edge Length", Range(0.0, 0.2)) = 0.1
		_RampTex ("Ramp", 2D) = "white" { }
		_StartPoint ("Start Point", Vector) = (0, 0, 0, 0)
		_MaxDistance ("Max Distance", Range(0.0, 100)) = 0
		_DistanceEffect ("Distance Effect", Range(0.0, 1.0)) = 0.5

		[Toggle(_SWITCH_ON)]_SWITCH ("Switch", int) = 0
	}
	SubShader
	{
		Tags{"RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" }
		Cull Off
		
		Pass
		{
			Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _SWITCH_ON
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			
			struct Attributes
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float2 texcoord : TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionHCS : SV_POSITION;
				float2 uvMainTex : TEXCOORD0;
				float2 uvNoiseTex : TEXCOORD1;
				float2 uvRampTex : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
				float3 worldNormal : TEXCOORD4;
				float3 localPos : TEXCOORD5;
			};

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_RampTex);SAMPLER(sampler_RampTex);
            CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
	            float4 _NoiseTex_ST;
	            float4 _RampTex_ST;
				half4 _Specular;
				half _Gloss;
				float _Threshold;
				float _EdgeLength;
				float _MaxDistance;
				float4 _StartPoint;
				float _DistanceEffect;
            CBUFFER_END
			
			Varyings vert(Attributes v)
			{
				Varyings  o = (Varyings)0;
				o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);

				o.uvMainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uvNoiseTex = TRANSFORM_TEX(v.texcoord, _NoiseTex);
				o.uvRampTex = TRANSFORM_TEX(v.texcoord, _RampTex);

				o.worldPos = TransformObjectToWorld(v.positionOS.xyz);
				o.worldNormal = TransformObjectToWorldNormal(v.normalOS);
				o.localPos = v.positionOS.xyz;

				return o;
			}
			
			half4 frag(Varyings i) : SV_Target
			{
				Light light = GetMainLight();
				float3 lightDir = light.direction;
				float3 lightColor = light.color * light.distanceAttenuation;
				
				float dist = length(i.localPos.xyz - _StartPoint.xyz);
				float normalizedDist = saturate(dist / _MaxDistance);
				#ifdef _SWITCH_ON
					return normalizedDist;
				#endif
				
				half cutout = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex , i.uvNoiseTex).r * (1 - _DistanceEffect) + normalizedDist * _DistanceEffect;
				clip(cutout - _Threshold);

				float degree = saturate((cutout - _Threshold) / _EdgeLength);
				half4 edgeColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex , float2(degree, degree));

				//漫反射
				half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uvMainTex);
				float3 worldNormal = normalize(i.worldNormal);
				half3 diffuse = lightColor.rgb * albedo.rgb * saturate(dot(worldNormal, lightDir) * 0.5 + 0.5);
				//BlinnPhong
				half3 viewDir = normalize(GetWorldSpaceViewDir(i.worldPos));
				half3 halfDir = normalize(lightDir + viewDir);
				half3 specular = lightColor.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
				half3 resCol = specular + diffuse;

				half4 finalColor = lerp(edgeColor, half4(resCol, 1), degree);
				return half4(finalColor.rgb, 1);
			}
			ENDHLSL

		}
	}
}
