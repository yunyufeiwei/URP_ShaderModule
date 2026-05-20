Shader "Unlit/yumao"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _FresnelScale("FreSnelScale",Range(0,10)) = 1
        _FresnelRange("FresnelRange",Range(0,20)) = 1
        _FresnelColor("FresnelColor",Color) = (1,1,1,1)
        _MaskTex ("MaskTex", 2D) = "white" {}
        _Alpha("Alpha",Range(0,1))= 1

    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent"}
        LOD 100

        
        Pass
        {
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half3 normal :NORMAL;

            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                half3 normal :TEXCOORD1;
                half3 posWorld :TEXCOORD2;
                UNITY_FOG_COORDS(3)

            };

            sampler2D _MainTex,_MaskTex;
            float4 _MainTex_ST,_MaskTex_ST;
            fixed4 _Color,_FresnelColor;
            half _FresnelScale,_FresnelRange,_Alpha;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i,fixed backface : VFACE) : SV_Target
            {
                float faceSign = ( backface >= 0 ? 1 : 0 );
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv)*_Color;
                fixed4 mask = tex2D(_MaskTex,i.uv);
				fixed fresnel =_FresnelScale *pow(1-saturate(dot(i.normal, viewDirection)),_FresnelRange);
                col.rgb+=fresnel*_FresnelColor;
                col.a*=mask.a+_Alpha;
                clip(col.a - 0.001);
                // apply fog
                // col.rbg = lerp(tex2D(_MainTex, i.uv).rgb*_Color,col.rgb,faceSign);
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
