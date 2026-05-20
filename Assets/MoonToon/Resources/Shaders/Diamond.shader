Shader "Unlit/Diamond"
{
   Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_ReflectionStrength ("Reflection Strength", Range(0.0,1)) = 1.0
		[NoScaleOffset] _RefractTex ("Refraction Texture", Cube) = "" {}
		
		_FresnelScale("FreSnelScale",Range(0,10)) = 1
		_FresnelRange("FresnelRange",Range(0,20)) = 1
		_FresnelColor("FresnelColor",Color) = (1,1,1,1)
		_Gloss("Gloss",Range(0,1)) = 1
		_GlossColor ("GlossColor", Color) = (1,1,1,1)
		_GlossPower ("GlossPower", Range(1,5)) = 1
		_MetalPlates("MetalPlates",2D) = "white"{}
		_LightDir("LightDir",Vector) = (.5,.5,.5,1)
		_LightPower("LightPower",Range(0,4)) = 1
		
		_Alpha("Alpha",Range(0,1)) = 1
   		}
	SubShader {
		Tags {
			"Queue" = "Transparent" "RenderType" = "Transparent"
		}
		Pass {
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			fixed4 _BackDiffuse;
			struct VertexInput {
				float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
			};


			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal :TEXCOORD2;
				float3 view :TEXCOORD3;
				float3 posWorld:TEXCOORD4;
			};

			v2f vert (VertexInput v)
			{
                v2f o = (v2f)0;
				o.pos = UnityObjectToClipPos(v.vertex);
				float3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
				o.uv = v.uv;
				o.normal = UnityObjectToWorldNormal(v.normal);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);

				return o;
			}

			fixed4 _Color,_FresnelColor,_GlossColor;
			samplerCUBE _RefractTex;
			sampler2D _MetalPlates;
			half4 _MetalPlates_ST;
			half _Emission,_FresnelScale,_Alpha,_FresnelRange,_ReflectionStrength,_Gloss,_GlossPower;
			fixed4 _LightDir;
			fixed _LightPower;
			
			half4 frag (v2f i) : SV_Target
			{
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 lightDirection = normalize(_LightDir.xyz);
                float3 halfDirection = normalize(viewDirection+lightDirection);
                float3 viewReflectDirection = reflect( -viewDirection, i.normal);
                float3 Specular = pow(max(0,dot(normalize(i.normal),halfDirection)),exp2(((_Gloss*10.0)+1.0)))*_GlossColor.rgb;

				fixed4 MetalPlatesVar = tex2D(_MetalPlates,TRANSFORM_TEX(i.uv,_MetalPlates));
				// fixed4 MetalPlatesVar = tex2D(_MetalPlates,i.pos.xy*.0005);

				
				half3 refraction = texCUBE(_RefractTex, viewReflectDirection).rgb *_ReflectionStrength;
				float ndl = saturate(dot(normalize(i.normal),lightDirection));
				fixed fresnel =_FresnelScale *pow(1-saturate(dot(i.normal, viewDirection)),_FresnelRange);
				fixed diffuse = (ndl)*_LightPower ;
				fixed3 lerpout = lerp(_Color.rgb,refraction*_Color.rgb,_ReflectionStrength);
				fixed3 lerpout2 = lerp(lerpout,fresnel*_FresnelColor.rgb,saturate(fresnel));
				// fixed3 othercolor =(lerpout2+Specular*_GlossPower)*MetalPlatesVar.r;
				fixed3 othercolor =lerp((lerpout2+Specular*_GlossPower),diffuse*_Color.rgb,MetalPlatesVar.r);

				return half4(othercolor, _Alpha);
				// return MetalPlatesVar;

			}
			ENDCG 
		}
        UsePass "VertexLit/SHADOWCASTER"
	}
}
