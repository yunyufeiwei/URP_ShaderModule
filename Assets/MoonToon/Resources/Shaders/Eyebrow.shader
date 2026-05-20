Shader "Unlit/Eyebrow" {
    Properties {
        _HairTex("Texture", 2D) = "white" {}
        _SpecularShift("Hair Shifted Texture", 2D) = "white" {}
        _DiffuseColor("DiffuseColor", Color) = (0.0, 0.0, 0.0, 0.0)
        _PrimaryColor("Specular1Color", Color) = (0.0, 0.0, 0.0, 0.0)
        _PrimaryShift("PrimaryShift", Range(-4, 4)) = 0.0
        _SecondaryColor("Specular2Color", Color) = (0.0, 0.0, 0.0, 0.0)
        _SecondaryShift("SecondaryShift", Range(-4, 4)) = 0.5
        
        _specPower("SpecularPower", Range(0, 50)) = 20
        _SpecularWidth("SpecularWidth", Range(0, 1)) = 0.5
        _SpecularScale("SpecularScale", Range(0, 1)) = 0.3
        [Header(Normal)]
        _NormalTex("NormalTexture", 2D) = "white" {}
        _NormalPower("NormalPower",Range(0,2)) = 1
        _Alpha("Alpha",Range(0,1)) = 1
        _LightPower("LightPower",Range(1,10))=1
    }
    SubShader {
        Pass{
            Tags {"RenderType"="Opaque"}
            ZWrite On
            ColorMask 0
        }
        Pass {
            Tags {
                "RenderType"="Transparent"  "Queue" = "AlphaTest"  "LightMode"="ForwardBase"
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

            sampler2D _HairTex,_NormalTex,_SpecularShift;
            half4 _HairTex_ST,_NormalTex_ST,_SpecularShift_ST;
            half4 _DiffuseColor,_PrimaryColor,_SecondaryColor;
            half _PrimaryShift,_SecondaryShift,_LightPower;
            fixed _specPower,_SpecularWidth,_SpecularScale;
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
                o.uv = v.uv;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                // half3 lightColor = _LightColor0.rgb;
                o.tangent = UnityObjectToWorldDir(v.tangent);
                o.binormal = cross(v.normal, v.tangent) * v.tangent.w * unity_WorldTransformParams.w;

                o.vertex = UnityObjectToClipPos( v.vertex );
                UNITY_TRANSFER_FOG(o,o.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
            fixed3 shiftTangent(fixed3 T, fixed3 N, fixed shift)
            {
                return normalize(T + shift * N);
            }
            fixed hairStrandSpecular(fixed3 T, fixed3 V, fixed3 L, fixed specPower)
            {
                fixed3 H = normalize(V + L);
                fixed HdotT = dot(T, H);
                fixed sinTH = sqrt(1 - HdotT * HdotT);
                fixed dirAtten = smoothstep(-_SpecularWidth, 0, HdotT);
                return dirAtten * saturate(pow(sinTH, specPower)) * _SpecularScale;
            }
            fixed4 getSpecular(fixed4 lightColor0, 
                               fixed4 primaryColor, fixed primaryShift,
                               fixed4 secondaryColor, fixed secondaryShift,
                               fixed3 N, fixed3 T, fixed3 V, fixed3 L, fixed specPower, fixed2 uv)
            {
                half shiftTex = tex2D(_SpecularShift, uv) ;

                fixed3 t1 = shiftTangent(T, N, primaryShift + shiftTex);
                fixed3 t2 = shiftTangent(T, N, secondaryShift + shiftTex);

                fixed4 specular = fixed4(0.0, 0.0, 0.0, 0.0);
                specular += primaryColor * hairStrandSpecular(t1, V, L, specPower) * _SpecularScale;;
                specular += secondaryColor * hairStrandSpecular(t2, V, L, specPower) * _SpecularScale;

                return specular;
            }

            half4 frag(VertexOutput i) : COLOR {
                half3 N = normalize(i.normalDir);
                half3 T = normalize(i.tangent);
                half3 B = normalize(i.binormal);
                half3 V = normalize(UnityWorldSpaceViewDir(i.posWorld));
                half3 L = normalize(_WorldSpaceLightPos0.xyz);

                half3x3 tangentTransform = half3x3( T*_NormalPower, B*_NormalPower, N);
				half3 _NormalTexVar = UnpackNormal(tex2D(_NormalTex,TRANSFORM_TEX(i.uv,_NormalTex)));
                half3 normalDirection = normalize(mul( _NormalTexVar, tangentTransform ));
                
                half attenuation = LIGHT_ATTENUATION(i);
                // half3 LightVar = (attenuation*(tex2D(_HairTex,TRANSFORM_TEX(i.uv, _HairTex))*(dot(L,N)*.5+.5)*_DiffuseColor+UNITY_LIGHTMODEL_AMBIENT.rgb)*_LightColor0.rgb);

                fixed4 specular = getSpecular(_LightColor0, _PrimaryColor, _PrimaryShift, _SecondaryColor, _SecondaryShift, normalDirection, T, V, L, _specPower, i.uv);
                // fixed4 col = ((half4(LightVar.rgb,1))*_LightPower + specular);
                // col.a = tex2D(_HairTex,TRANSFORM_TEX(i.uv, _HairTex)).a*_Alpha;


                half4 col = tex2D(_HairTex,TRANSFORM_TEX(i.uv,_HairTex))*_DiffuseColor+specular;
                half lbt = saturate(dot(L,normalDirection) *.5+.5);
                half4 outc = half4(0,0,0,0);
                outc.rgb = half3(lbt,lbt,lbt) *col.rgb*attenuation*(_LightColor0.rgb *_LightPower);//
                outc.a = tex2D(_HairTex,TRANSFORM_TEX(i.uv,_HairTex)).a*_Alpha;
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
    FallBack "VertexLit"
}
