Shader "Unlit/Matel"
{
   Properties {
		_Color ("Color", Color) = (1,1,1,1)
		[NoScaleOffset] _RefractTex ("Refraction Texture", Cube) = "" {}
        _RefPower("RefPower",Range(0,1)) = 1
		_FresnelScale("FreSnelScale",Range(0,10)) = 1
		_FresnelRange("FresnelRange",Range(0,20)) = 1
		_FresnelColor("FresnelColor",Color) = (1,1,1,1)
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
				o.view = normalize(UnityWorldSpaceViewDir(mul(unity_ObjectToWorld, v)));
				o.normal = UnityObjectToWorldNormal(n);
				return o;
			}

			fixed4 _Color,_FresnelColor;
			samplerCUBE _RefractTex;
			half _Emission,_FresnelScale,_FresnelRange,_RefPower;
			
			half4 frag (v2f i) : SV_Target
			{
				half3 refraction = texCUBE(_RefractTex, i.uv).rgb;
				float ndl = saturate(dot(normalize(i.normal),normalize(_WorldSpaceLightPos0.xyz)));
				fixed3 diffuse = (ndl*0.5 + 0.5) * _Color.rgb ;
				fixed3 fresnel =_FresnelScale *  pow(1-saturate(dot(i.normal, i.view)),_FresnelRange)*_FresnelColor;
				return half4((refraction.rgb*_RefPower)+diffuse+fresnel, 1);
			}
			ENDCG 
		}
        UsePass "VertexLit/SHADOWCASTER"
	}
}
