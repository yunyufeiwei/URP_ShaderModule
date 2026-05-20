Shader "Unlit/QJNN/HairShader2"
{
    Properties
    {
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
        _LightPower("LightPower",Range(1,5))=1
    }
    SubShader
    {
        Tags {"RenderPipeline"="UniversalPipeline" "RenderType"="Transparent"  "Queue" = "Transparent"}

        LOD 100
        Pass
        {
            // Cull Off
            ZWrite On
            ColorMask 0
        }
        
        Pass
        {
            Tags { "LightMode"="UniversalForward" }
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                half4 vertex : POSITION;
                half2 uv : TEXCOORD0;
                half3 normal: NORMAL;
                half4 tangent: TANGENT;
            };

            struct v2f
            {
                half2 uv : TEXCOORD0;
                half4 vertex : SV_POSITION;
                half3 tangent : TEXCOORD1;
                half3 normal : TEXCOORD2;
                half3 binormal: TEXCOORD3;
                half3 pos : TEXCOORD4;
                UNITY_FOG_COORDS(1)
            };

            sampler2D _HairTex,_NormalTex;
            half4 _HairTex_ST,_NormalTex_ST;
            sampler2D _SpecularShift;
            half4 _SpecularShift_ST;

            half4 _DiffuseColor;
            half4 _PrimaryColor;
            half _PrimaryShift;
            half4 _SecondaryColor;
            half _SecondaryShift,_LightPower;
            fixed _specPower,_SpecularWidth,_SpecularScale;
            fixed _NormalPower,_Alpha;

            v2f vert (appdata v)
            {
                v2f o;
                
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _HairTex);

                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent = UnityObjectToWorldDir(v.tangent);
                o.binormal = cross(v.normal, v.tangent) * v.tangent.w * unity_WorldTransformParams.w;
                o.pos = mul(unity_ObjectToWorld, v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
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

            // fixed4 getAmbientAndDiffuse(fixed4 lightColor0, fixed4 diffuseColor, fixed3 N, fixed3 L, fixed2 uv)
            // {
            //     return (lightColor0 * diffuseColor * saturate(dot(N, L)) + fixed4(0.2, 0.2, 0.2, 1.0)) * tex2D(_HairTex, uv)*_LightPower;
            // }

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

            fixed4 frag (v2f i) : SV_Target
            {
                half3 N = normalize(i.normal);
                half3 T = normalize(i.tangent);
                half3 B = normalize(i.binormal);
                half3 V = normalize(UnityWorldSpaceViewDir(i.pos));
                half3 L = normalize(_WorldSpaceLightPos0.xyz);

                half3 L2 = Shade4PointLights(unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
					unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
					unity_4LightAtten0,
					i.pos, N);

                half3x3 tangentTransform = half3x3( T*_NormalPower, B*_NormalPower, N);
				half3 _NormalTexVar = UnpackNormal(tex2D(_NormalTex,TRANSFORM_TEX(i.uv,_NormalTex)));
                half3 normalDirection = normalize(mul( _NormalTexVar, tangentTransform ));

                // fixed4 ambientdiffuse = getAmbientAndDiffuse(_LightColor0, _DiffuseColor, normalDirection, L, i.uv);
                fixed4 specular = getSpecular(_LightColor0, _PrimaryColor, _PrimaryShift, _SecondaryColor, _SecondaryShift, normalDirection, T, V, L, _specPower, i.uv);
                
                fixed4 col = ((half4(L2.rgb,1))*tex2D(_HairTex,i.uv)*_LightPower + specular);
                col.a = tex2D(_HairTex, i.uv).a*_Alpha;
                // UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
        
    }
    Fallback "Diffuse"
}