Shader "Art_URP/FunctionTest/Polar3"
{
    Properties
    {
        _Num ("Num", Float) = 10
        _Smooth("Smooth" , float) = 1
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" }
        LOD 100

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
                float  _Num;
                float  _Smooth;
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
                half2 uv = i.uv -0.5;

                half r = length(uv) * 2.0;          //将uv的原型变换到中心
                half a = atan2(uv.y , uv.x) * _Num;  //极坐标

                half f = cos(a);

                half polar = smoothstep(f, f + _Smooth , r);

                FinalColor = polar;

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
