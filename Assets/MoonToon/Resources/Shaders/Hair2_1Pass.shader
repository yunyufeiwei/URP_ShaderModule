Shader "Unlit/Hair2_1Pass" {
    Properties {
        _MainColor("MainColor", Color) = (1,1,1,1)
        _BackColor("BackColor",Color) = (1,1,1,1)
        _HairTex("Texture", 2D) = "white" {}
        _SpecularShift("Hair Shifted Texture", 2D) = "white" {}
        _PrimaryColor("Specular1Color", Color) = (0.0, 0.0, 0.0, 0.0)
        _PrimaryShift("PrimaryShift", Range(0, 1)) = 0.0
        // _SecondaryColor("Specular2Color", Color) = (0.0, 0.0, 0.0, 0.0)
        // _SecondaryShift("SecondaryShift", Range(-4, 4)) = 0.5
        
        _SpecularRange("SpecularRange", Range(0, 256)) = 20
        _SpecularPower("SpecularPower", Range(0, 5)) = 1
        // _SpecularWidth("SpecularWidth", Range(0, 1)) = 0.5
        // _SpecularScale("SpecularScale", Range(0, 2)) = 0.3
        [Header(SpecularMask)]
        _SpecularMask("SpecularMask",2D) = "white"{}
        [Header(OtherGloss)]
        _Gloss("Gloss",Range(0,1)) = 1
        _GlossColor("GlossColor",Color) = (1,1,1,1)
        [Header(Normal)]
        _NormalTex("NormalTexture", 2D) = "white" {}
        _NormalPower("NormalPower",Range(0,2)) = 1
        _Alpha("Alpha",Range(0,1)) = 1
        _LightPower("LightPower",Range(1,10))=1
        [Header(Ramp)]
        _RampTexture("Ramp",2D) = "white"{}
    }
    SubShader {
        Pass{
            Tags {"RenderType"="Opaque"}
            ZWrite On
            ColorMask 0
        }
        Pass {
            Tags {
                "RenderType"="Transparent"  "Queue" = "Transparent"  "LightMode"="ForwardBase"
            }
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma multi_compile_fog

            sampler2D _HairTex,_NormalTex,_SpecularShift,_SpecularMask,_RampTexture;
            half4 _HairTex_ST,_NormalTex_ST,_SpecularShift_ST,_SpecularMask_ST,_RampTexture_ST;
            half4 _MainColor,_PrimaryColor,_SecondaryColor,_GlossColor,_BackColor;
            half _PrimaryShift,_SecondaryShift,_LightPower;
            fixed _SpecularRange,_SpecularWidth,_SpecularScale;
            fixed _NormalPower,_Alpha,_Gloss,_SpecularPower;

            struct VertexInput {
                half4 vertex : POSITION;
                half3 normal : NORMAL;
                half2 uv : TEXCOORD0;
                half4 tangent: TANGENT;
            };
            struct VertexOutput {
                half4 vertex : SV_POSITION;
                half2 uv : TEXCOORD0;
                half3 posWorld : TEXCOORD1;
                half3 normalDir : TEXCOORD2;
                half3 tangent : TEXCOORD3;
                half3 binormal: TEXCOORD4;

                LIGHTING_COORDS(5,6)
                UNITY_FOG_COORDS(7)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.vertex = UnityObjectToClipPos( v.vertex );
                o.uv = v.uv;
                o.posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normalDir = UnityObjectToWorldNormal(v.normal);

                // half3 lightColor = _LightColor0.rgb;
                o.tangent = UnityObjectToWorldDir(v.tangent);
                o.binormal = cross(o.normalDir, o.tangent) ;
                UNITY_TRANSFER_FOG(o,o.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
            // fixed3 shiftTangent(fixed3 T, fixed3 N, fixed shift)
            // {
            //     return normalize(T + shift * N);
            // }
            // fixed hairStrandSpecular(fixed3 T, fixed3 V, fixed3 L, fixed specPower)
            // {
            //     fixed3 H = normalize(V + L);
            //     fixed HdotT = dot(T, H);
            //     fixed sinTH = sqrt(1 - HdotT * HdotT);
            //     fixed dirAtten = smoothstep(-_SpecularWidth, 0, HdotT);
            //     return dirAtten * saturate(pow(sinTH, specPower)) * _SpecularScale;
            // }
            // fixed4 getSpecular(fixed4 lightColor0, 
            //                    fixed primaryShift,
            //                    fixed4 secondaryColor, fixed secondaryShift,
            //                    fixed3 N, fixed3 T, fixed3 V, fixed3 L, fixed specPower, fixed2 uv)
            // {
            //     half shiftTex = tex2D(_SpecularShift, uv) ;

            //     // fixed3 t1 = shiftTangent(T, N, primaryShift + shiftTex);
            //     // fixed3 t2 = shiftTangent(T, N, secondaryShift + shiftTex);

            //     fixed4 specular = fixed4(0.0, 0.0, 0.0, 0.0);
            //     specular +=  hairStrandSpecular(N, V, L, specPower) * _SpecularScale;;
            //     // specular += secondaryColor * hairStrandSpecular(t2, V, L, specPower) * _SpecularScale;

            //     return specular;
            // }

            half4 frag(VertexOutput i) : COLOR {
                half3 N = normalize(i.normalDir);
                half3 T = normalize(i.tangent);
                half3 B = normalize(i.binormal);
                half3 V = normalize(UnityWorldSpaceViewDir(i.posWorld));
                half3 L = normalize(UnityWorldSpaceLightDir(i.posWorld));
                half3 R = normalize(L+V);
                fixed3 AnisotropicworldNormal = normalize(lerp(i.normalDir + i.binormal, i.binormal, _PrimaryShift));
                float Anisotropic2 = dot(AnisotropicworldNormal, R);
				fixed4 specular = fixed4(_LightColor0.rgb * _PrimaryColor.rgb * pow(max(0, sqrt(1 - (Anisotropic2 * Anisotropic2))), _SpecularRange),1);


                half3x3 tangentTransform = half3x3( T*_NormalPower, B*_NormalPower, N);
				half3 _NormalTexVar = UnpackNormal(tex2D(_NormalTex,TRANSFORM_TEX(i.uv,_NormalTex)));
                half3 normalDirection = normalize(mul( _NormalTexVar, tangentTransform ));
                
                half attenuation = LIGHT_ATTENUATION(i);
                half lbt2 = saturate(dot(L,normalDirection));
                half lbt = saturate(dot(L,normalDirection)*.5+.5);
                half4 ramp = tex2D(_RampTexture,half2(lbt,lbt));
                // fixed4 col = ((half4(LightVar.rgb,1))*_LightPower + specular);
                // col.a = tex2D(_HairTex,TRANSFORM_TEX(i.uv, _HairTex)).a*_Alpha;
                half4 specularMaskVar = tex2D(_SpecularMask,TRANSFORM_TEX(i.uv,_SpecularMask));
                half gloss3 = pow(max(0,dot(N,normalize(V+L))),exp2(((_Gloss*10.0)+1.0)));
                half4 col = tex2D(_HairTex,TRANSFORM_TEX(i.uv,_HairTex))*_MainColor+(gloss3*_GlossColor)+(lbt2*specular*specularMaskVar.r)*_SpecularPower;//
                

                // half3 backcolor =saturate( dot(L,normalDirection)*-1)*_BackColor;
                // half3 LightVar = half3(lbt,lbt,lbt)+backcolor;
                half3 LightVar = lerp(_BackColor,_MainColor,ramp.r);

                half4 outc = half4(0,0,0,0);
                outc.rgb =  LightVar*col.rgb*attenuation*(_LightColor0.rgb *_LightPower);//
                outc.a = tex2D(_HairTex,TRANSFORM_TEX(i.uv,_HairTex)).a*_Alpha;
                UNITY_APPLY_FOG(i.fogCoord, col);
                // half4 temp =half4(LightVar,1);
                return outc;
            }
            ENDCG
        }
        Pass {
            Tags {
                "LightMode"="ForwardAdd" "RenderType"="Transparent"
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

            sampler2D _HairTex,_NormalTex,_SpecularShift;
            half4 _HairTex_ST,_NormalTex_ST,_SpecularShift_ST;
            half4 _MainColor,_PrimaryColor,_SecondaryColor;
            half _PrimaryShift,_SecondaryShift,_LightPower;
            fixed _SpecularRange,_SpecularWidth,_SpecularScale;
            fixed _NormalPower,_Alpha;

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
                UNITY_TRANSFER_FOG(o,o.pos);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
            half4 frag(VertexOutput i) : COLOR {
                half3 N = normalize(i.normalDir);
                fixed3 L = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz,_WorldSpaceLightPos0.w));
                fixed attenuation = LIGHT_ATTENUATION(i);
                fixed4 HairTex_var = tex2D(_HairTex,TRANSFORM_TEX(i.uv, _HairTex));

                fixed3 LightVar = (attenuation*((HairTex_var.rgb*(dot(L,N)*0.5+0.5))+UNITY_LIGHTMODEL_AMBIENT.rgb)*_LightColor0.rgb);
                fixed4 outc = fixed4(LightVar,HairTex_var.a);
                UNITY_APPLY_FOG(i.fogCoord, outc);
                return fixed4(LightVar,HairTex_var.a);
            }
            ENDCG
        }
    }
    FallBack "VertexLit"
}
