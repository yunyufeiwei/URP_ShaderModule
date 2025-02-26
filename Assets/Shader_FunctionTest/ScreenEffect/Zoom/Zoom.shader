// ---------------------------【放大镜特效】---------------------------
Shader "Art_URP/FunctionTest/ScreenPost/Zoom"
{
    Properties
    {
          [HideInInspector]_MainTex ("Texture", 2D) = "white" {}
//        _Pos("Pos" , Vector) = (0,0,0,0)
//        _ZoomFactor("ZoomFactor" , Float) = 0
//        _EdgeFactor("EdgeFactor" , Float) = 0
//        _Size("Size" , Float) = 0
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" }
        Cull Off ZWrite Off ZTest Always
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            //顶点输入结构体
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
            };
            // 顶点输出结构体
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            CBUFFER_START(UnityPerMaterial)
                float2 _Pos;
                float _ZoomFactor;
                float _EdgeFactor;
                float _Size;
            CBUFFER_END
            
            // ---------------------------【顶点着色器】---------------------------
            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings) 0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.texcoord;
                return o;
            }
            // ---------------------------【片元着色器】---------------------------
            half4 frag (Varyings i) : SV_Target
            {
                //屏幕长宽比 缩放因子
                float2 scale = float2(_ScreenParams.x / _ScreenParams.y, 1);
                // 放大区域中心
                float2 center = _Pos;
                float2 dir = center - i.uv;
                
                //当前像素到中心点的距离
                float dis = length(dir * scale);
                // 是否在放大镜区域
                // fixed atZoomArea = 1-step(_Size,dis);
                float atZoomArea = smoothstep(_Size + _EdgeFactor,_Size,dis );

                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv + dir * _ZoomFactor * atZoomArea );
                return col;
            }
            ENDHLSL
        }
    }
}
