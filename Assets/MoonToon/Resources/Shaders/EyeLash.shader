Shader "Unlit/QJNN/EyeLash"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Tint("Tint",Color)=(1,1,1,1)
		_FrontSurfaceDistortion("FrontSurfaceDistortion",Range(0,2)) = 1
		_BackSurfaceDistortion("BackSurfaceDistortion",Range(0,2)) = 1
		_InteriorColor("InteriorColor",Color) = (1,1,1,1)
		_InteriorColorPower("InteriorColorPower",Range(0,1)) = 1
		_FrontSSSIntensity("FrontSSSIntensity",Range(0,1)) = 1
		_Gloss("Gloss",Range(0,1))=1
		_RimPower("RimPower",Range(0.1,1))=1
		_RimIntensity("RimIntensity",Range(0,2))=1
		[Header(Noraml)]
		_NormalTex ("NormalTexture", 2D) = "Bump" {}
		_NormalPower("NormalPower",Range(0,2))=1
		[Header(Mask)]
		_MaskTexture("MaskTexture",2D) = "white"{}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
				half4 tangent :TANGENT;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 worldPos:TEXCOORD1;
				float3 worldNormal:TEXCOORD2;
				half3 tangentDir : TEXCOORD3;
                half3 bitangentDir : TEXCOORD4;
			};

			sampler2D _MainTex,_NormalTex,_MaskTexture;
			float4 _MainTex_ST,_NormalTex_ST,_MaskTexture_ST;
			float4 _InteriorColor;
			float _InteriorColorPower;
			float _FrontSurfaceDistortion,_BackSurfaceDistortion,_FrontSSSIntensity,_Gloss;
			float4 _Tint;
			float _RimPower,_RimIntensity;
			half _NormalPower;
			
			float SubSurfaceScattering(float3 viewDir,float3 lightDir,float3 normalDir,float frontSubSurfaceDistortion,float backSubSurfaceDistortion,float frontSSSIntensity) {
				//计算正面和背面次表面散射
				float3 frontLitDir = normalDir * frontSubSurfaceDistortion - lightDir;
				float3 backLitDir = normalDir * backSubSurfaceDistortion + lightDir;
				float frontSSS = saturate(dot(viewDir, -frontLitDir));
				float backSSS = saturate(dot(viewDir, -backLitDir));
				float result = saturate(frontSSS * frontSSSIntensity + backSSS);
				return result;
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.tangentDir = normalize(mul(unity_ObjectToWorld,float4(v.tangent.xyz,0)).xyz);
                o.bitangentDir = normalize(cross(o.worldNormal,o.tangentDir)*v.tangent.w);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float4 col = tex2D(_MainTex,i.uv)*_Tint;
				half3 mask_Var = tex2D(_MaskTexture,i.uv); //r粗糙度, g,sss通道  b.ao
				float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos).xyz);
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float3 normal = normalize(i.worldNormal.xyz);
				
				//normal
				float3x3 tangentTransform = float3x3( i.tangentDir*_NormalPower, i.bitangentDir*_NormalPower, normal);
				float3 _NormalTexVar = UnpackNormal(tex2D(_NormalTex,TRANSFORM_TEX(i.uv,_NormalTex)));
                float3 normalDirection = normalize(mul( _NormalTexVar, tangentTransform ));
				
				//SSS
				float SSS = SubSurfaceScattering(viewDir, lightDir, normalDirection, _FrontSurfaceDistortion,_BackSurfaceDistortion,_FrontSSSIntensity);
				float3 SSSCol = lerp(_InteriorColor, _LightColor0, saturate(pow(SSS, _InteriorColorPower))).rgb*SSS*mask_Var.g;
				//Diffuse
				float4 unLitCol = col * _InteriorColor*0.5;
				float diffuse = dot(normalDirection, lightDir)*.5+.5;
				float4 diffuseCol = lerp(unLitCol,col,diffuse);
				//Specular
				float specularPow = exp2((1 - _Gloss) * 10 + 1);
				float3 halfDir = normalize(lightDir + viewDir);
				float3 specular = pow(max(0, dot(halfDir, normalDirection)), specularPow);
				specular *= _LightColor0.rgb*mask_Var.r;

				// float3 final = SSSCol+ diffuseCol.rgb+rimCol;
				float3 final = specular;

				return float4(final,1);
			}
			ENDCG
		}
	}
    FallBack "VertexLit"
}