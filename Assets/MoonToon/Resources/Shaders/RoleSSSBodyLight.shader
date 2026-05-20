Shader "Unlit/QJNN/SimpleSSSLight"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Tint("Tint",Color)=(1,1,1,1)
		_FrontSurfaceDistortion("FrontSurfaceDistortion",Range(0,2)) = 1
		_BackSurfaceDistortion("BackSurfaceDistortion",Range(0,2)) = 1
		_BackIntensity("BackIntensity",Range(0,1)) = 0
		_InteriorColor("InteriorColor",Color) = (1,1,1,1)
		_InteriorColorPower("InteriorColorPower",Range(0,1)) = 1
		_FrontSSSIntensity("FrontSSSIntensity",Range(0,1)) = 1
		_Gloss("Gloss",Range(0,1))=1
		_GlossColor("GlossColor",Color) = (1,1,1,1)
		_RimPower("RimPower",Range(0.1,5))=1
		_RimIntensity("RimIntensity",Range(0,2))=1
		[Header(Noraml)]
		_NormalTex ("NormalTexture", 2D) = "Bump" {}
		_NormalPower("NormalPower",Range(0,2))=1
		[Header(Mask)]
		_MaskTexture("MaskTexture",2D) = "white"{}
		_AoIntensity("AoIntensity",Range(0,1))= 0
		_AoColor("AoColor" ,Color) = (1,1,1,1)
		_MaskVarRPower("R",Range(0,1)) = 0
		_Ramp("Ramp",2D) = "white"{}
		_RampColor("RampColor",Color) = (1,1,1,1)
		_demo("demo",Vector) = (1,1,1,1)
		_LightPower("PointLightIntensity",Float) = 1
		_LightMaskTex("LightMaskTex",2D)= "black"{}
	}
	SubShader
	{
		Pass
		{
			Tags { "RenderType"="Opaque"  "LightMode"="ForwardBase"}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
            #include "AutoLight.cginc"

			struct appdata
			{
				half4 vertex : POSITION;
				half2 uv : TEXCOORD0;
				half3 normal:NORMAL;
				half4 tangent :TANGENT;
			};

			struct v2f
			{
				half2 uv : TEXCOORD0;
				half4 vertex : SV_POSITION;
				half3 worldPos:TEXCOORD1;
				half3 worldNormal:TEXCOORD2;
				half3 tangentDir : TEXCOORD3;
                half3 bitangentDir : TEXCOORD4;
                LIGHTING_COORDS(5,6)
                UNITY_FOG_COORDS(7)
			};

			sampler2D _MainTex,_NormalTex,_MaskTexture,_Ramp;
			half4 _MainTex_ST,_NormalTex_ST,_MaskTexture_ST,_Ramp_ST;
			half4 _InteriorColor;
			half _InteriorColorPower;
			half _FrontSurfaceDistortion,_BackSurfaceDistortion,_FrontSSSIntensity,_Gloss;
			half4 _Tint,_GlossColor,_AoColor,_RampColor;
			half _RimPower,_RimIntensity;
			half _NormalPower,_AoIntensity,_MaskVarRPower,_BackIntensity;
			half4 _demo;
			
			half SubSurfaceScattering(half3 viewDir,half3 lightDir,half3 normalDir,half frontSubSurfaceDistortion,half backSubSurfaceDistortion,half frontSSSIntensity) {
				//计算正面和背面次表面散射
				half3 frontLitDir = normalDir * frontSubSurfaceDistortion - lightDir;
				half3 backLitDir = normalDir * backSubSurfaceDistortion + lightDir;
				half frontSSS = saturate(dot(viewDir, -frontLitDir));
				half backSSS = saturate(dot(viewDir, -backLitDir));
				half result = saturate(frontSSS * frontSSSIntensity + backSSS);
				return result;
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.tangentDir = normalize(mul(unity_ObjectToWorld,half4(v.tangent.xyz,0)).xyz);
                o.bitangentDir = normalize(cross(o.worldNormal,o.tangentDir)*v.tangent.w);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half3 normal = normalize(i.worldNormal.xyz);
				// half3 L = Shade4PointLights(unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
				// 	unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
				// 	unity_4LightAtten0,
				// 	i.worldPos, normal);
				half attenuation = LIGHT_ATTENUATION(i);

				half3 col = tex2D(_MainTex,i.uv);
				half3 mask_Var = tex2D(_MaskTexture,i.uv); //r粗糙度, g,sss通道  b.ao
				half3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos).xyz);
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

				//normal
				half3x3 tangentTransform = half3x3( i.tangentDir*_NormalPower, i.bitangentDir*_NormalPower, normal);
				half3 _NormalTexVar = UnpackNormal(tex2D(_NormalTex,TRANSFORM_TEX(i.uv,_NormalTex)));
                half3 normalDirection = normalize(mul( _NormalTexVar, tangentTransform ));
				
				//SSS
				half SSS = SubSurfaceScattering(viewDir, lightDir, normalDirection, _FrontSurfaceDistortion,_BackSurfaceDistortion,_FrontSSSIntensity);
				half3 SSSCol = lerp(_InteriorColor, _LightColor0, saturate(pow(SSS, _InteriorColorPower))).rgb*SSS*mask_Var.g;
				//Diffuse
				half3 unLitCol = col * _RampColor*0.5;
				half blbt = saturate(dot((normal), saturate(lightDir))*.5+.5);
				// half diffuse = saturate(lbt);
				
				fixed3 ramp_var = tex2D(_Ramp,half2(blbt-_demo.x,blbt)-_demo.y).rgb ;


				half3 diffuseCol = lerp(unLitCol,col*_Tint.rgb,saturate(ramp_var.r));
				//Specular
				half specularPow = exp2((1 - _Gloss) * 10 + 1);
				half3 halfDir = normalize(lightDir + viewDir);
				half3 specular = pow(max(0, dot(halfDir, normalDirection)), specularPow);
				specular *= _LightColor0.rgb*(mask_Var.r+_MaskVarRPower)*_GlossColor.rgb;
				//Rim
				half rim = 1.0 - max(0, dot(normalDirection, viewDir));
				half rimValue = lerp(rim, 0, SSS);
				half3 rimCol = lerp(_InteriorColor, _LightColor0.rgb, rimValue)*pow(rimValue, _RimPower)*_RimIntensity;
				
				// half3 final = SSSCol+ diffuseCol.rgb+rimCol;
				half3 final = (SSSCol+diffuseCol.rgb+specular +(rimCol*ramp_var.r))*lerp(_AoColor,fixed3(1,1,1),saturate(mask_Var.b+_AoIntensity))*attenuation;
				half4 outc = half4(final,1)*_LightColor0;
                UNITY_APPLY_FOG(i.fogCoord, outc);
				return outc;
			}
			ENDCG
		}
		Pass {
            Tags {
                "LightMode"="ForwardAdd"
            }
            Blend One One
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog

			sampler2D _MainTex,_Ramp,_LightMaskTex;
			half4 _MainTex_ST,_Ramp_ST,_LightMaskTex_ST;
			half _LightPower;

            struct VertexInput {
                half4 vertex : POSITION;
                half3 normal : NORMAL;
                half2 uv : TEXCOORD0;
                half4 tangent: TANGENT;
            };
            struct VertexOutput {
                half4 vertex : SV_POSITION;
                half2 uv : TEXCOORD0;
                half4 posWorld : TEXCOORD1;
                half3 normalDir : TEXCOORD2;
                half3 tangent : TEXCOORD3;
                half3 binormal: TEXCOORD4;
                LIGHTING_COORDS(5,6)
                UNITY_FOG_COORDS(7)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = UnityObjectToClipPos( v.vertex );
				o.uv= v.uv;
                UNITY_TRANSFER_FOG(o,o.pos);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
            half4 frag(VertexOutput i) : COLOR {
                half3 N = normalize(i.normalDir);
                fixed3 L = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz,_WorldSpaceLightPos0.w));
				float3 L2 = normalize(_WorldSpaceLightPos0.xyz);
                fixed attenuation = LIGHT_ATTENUATION(i)*_LightPower;
                fixed4 Maintex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv, _MainTex));

				half4 lightmaskvar = tex2D(_LightMaskTex,TRANSFORM_TEX(i.uv,_LightMaskTex));
				half lbt = dot(L2,N)*.5+.5;
				// half4 ramptex = tex2D(_Ramp,half2(lbt,lbt));

                fixed3 LightVar = (attenuation*((Maintex_var.rgb*lbt)+UNITY_LIGHTMODEL_AMBIENT.rgb)*_LightColor0.rgb);
                fixed4 outc = fixed4(LightVar,Maintex_var.a)*(1-lightmaskvar.g);
                UNITY_APPLY_FOG(i.fogCoord, outc);
                return outc;
            }
            ENDCG
        }
	}
    FallBack "Diffuse"
}
