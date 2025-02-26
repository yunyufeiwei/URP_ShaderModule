Shader "Art_URP/FunctionTest/RisingSun"
{
    Properties
    {
        _Num ("Num", float) = 10
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" }

        Pass
        {
            Tags{"RenderPipeline" = "UniversalPipeline"}
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/ShaderLibs/MF_DrawShape.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID      //GPU实例化
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            CBUFFER_START(UnityPerMaterial)
                float   _Num;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                UNITY_SETUP_INSTANCE_ID(v);

                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.texcoord;
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                half4 FinalColor;

                half2 uv = i.uv - 0.5;
                half a = atan2(uv.y , uv.x) * _Num;

                half f = cos(a);
                half cir = Circle(float2(0.5,0.5) , 0.2 , i.uv);        //计算出圆环
                half3 cirColor = cir * half3(1,0,0);

                half3 lineCol = (1 - cir) * ((1 - f) + f * half3(0.9,0.9,0.0));

                FinalColor = half4(cirColor + lineCol , 1.0);

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
