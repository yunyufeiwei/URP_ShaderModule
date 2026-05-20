Shader "Unlit/zhenzhu"
{
   Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_ReflectionStrength ("Reflection Strength", Range(0.0,2.0)) = 1.0
		_Emission ("Emission", Range(0.0,2.0)) = 0.0
		// [NoScaleOffset] _RefractTex ("Refraction Texture", Cube) = "" {}
		
		_FresnelScale("FreSnelScale",Range(0,10)) = 1
		_FresnelRange("FresnelRange",Range(0,20)) = 1
		_FresnelColor("FresnelColor",Color) = (1,1,1,1)

		_Alpha("Alpha",Range(0,1)) = 1
   		}
	SubShader {
		Tags {
			"Queue" = "Geometry" "RenderType" = "Opaque"
		}
		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct v2f {
				float4 pos : SV_POSITION;
				float3 uv : TEXCOORD0;
				float3 normal :TEXCOORD2;
				float3 view :TEXCOORD3;
			};

			v2f vert (float4 v : POSITION, float3 n : NORMAL)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v);
				float3 viewDir = normalize(ObjSpaceViewDir(v));
				o.uv = -reflect(viewDir, n);
				o.uv = mul(unity_ObjectToWorld, float4(o.uv,0));
				o.view = viewDir;
				o.normal = UnityObjectToWorldNormal(n);
				return o;
			}

			fixed4 _Color,_FresnelColor;
			samplerCUBE _RefractTex;
			half _Emission,_FresnelScale,_FresnelRange,_Alpha;
			
			half4 frag (v2f i) : SV_Target
			{
				// half3 refraction = texCUBE(_RefractTex, i.uv).rgb ;
				// half4 reflection = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, i.uv);
				// reflection.rgb = DecodeHDR (reflection, unity_SpecCube0_HDR);
				// half3 multiplier = reflection.rgb  + _Emission;
				float ndl = saturate(dot(normalize(i.normal),normalize(_WorldSpaceLightPos0.xyz)))*0.5 + 0.5;
				fixed3 fresnel =_FresnelScale *  pow(1-saturate(dot(i.normal, i.view)),_FresnelRange)*_FresnelColor;	
				fixed3 diffuse =  _Color.rgb*ndl+fresnel ;
				return half4( diffuse, _Alpha);//refraction.rgb * multiplier.rgb *
			}
			ENDCG 
		}
        UsePass "VertexLit/SHADOWCASTER"
	}
}
