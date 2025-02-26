Shader "Art_URP/FunctionTest/Flower"
{
    Properties
    {
        _Num("Num" , float) = 5
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

                half r = length(uv) * 2.0;
                half a = atan2(uv.y , uv.x) * _Num;

                half f = abs(cos(a)) * 0.5 + 0.3;
                float cir = Circle(float2(0.5, 0.5), 0.15, i.uv);
				float cir2 = Circle(float2(0.5, 0.5), 0.13, i.uv);

                //1 - cir保证花瓣的函数在中间圆之外执行，step(f, r) * step(r, f + 0.1)描边，(1 - step(f, r)) * fixed3(1, 0, 1)花瓣着色
				half3 col1 = (1 - cir) * (1 - (step(f, r) * step(r, f + 0.1) + (1 - step(f, r)) * half3(1, 0, 1)));
				half3 col2 = (1 - cir2) * cir * half3(1, 0, 1) + cir2 * half3(1, 0, 0);
				FinalColor = half4(col1 + col2 , 1.0);

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
