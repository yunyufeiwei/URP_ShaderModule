Shader "Unlit/jianying"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Scale("Scale",Vector)= (1,1,1,1)
        _Color1("Color1",Color) = (1,1,1,1)
        _Color2("Color2",Color) = (1,1,1,1)
        _WorldPos("WorldPos",Float) = 0
        _WorldPosRange("WorldPosRange",Range(1,50)) = 1
        _Alpha("Alpha" , Range(0,1)) = 1
        _Pix("Pix",Range(0,1)) = 1

    }
    SubShader
    {
        Tags { "RenderType"="Opaque"  "Queue" = "Geometry" }
        LOD 100
//        Cull Front
//        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Cull Off
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 worldPos :TEXCOORD1;
                float4 screenPos:TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Scale;
            fixed4 _Color1,_Color2;
            half _WorldPos,_WorldPosRange ,_Alpha;
            float _Pix;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.uv= v.uv;
                // o.uv = worldPos.xy*_Scale.xy+_Scale.zw;
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed3 lerpColor = lerp(_Color1,_Color2,saturate((i.worldPos.y+_WorldPos)*_WorldPosRange));
                col.rgb*=lerpColor;

                // float4x4 thresholdMatrix =
                // {  1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
                // 13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
                // 4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
                // 16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
                // };
                // float4x4 _RowAccess = { 1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1 };
                // float2 pos = i.screenPos.xy / i.screenPos.w;
                // pos *= _ScreenParams.xy*_Pix; // pixel position
                // clip(_Alpha - thresholdMatrix[fmod(pos.x, 4)] * _RowAccess[fmod(pos.y, 4)]);



                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
