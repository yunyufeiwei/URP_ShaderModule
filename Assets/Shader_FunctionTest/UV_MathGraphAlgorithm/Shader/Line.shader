Shader "Art_URP/FunctionTest/Line"
{
    Properties
    {
        _StartEnd ("Start(XY) End(ZW)", Vector) = (0.5, 0.5, 0, 0)
        _Width ("Width", Range(0, 1)) = 0.01
        _Antialias ("Antialias Width", Range(0, 0.1)) = 0.001
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
                float4 _StartEnd;
                float  _Width;
                float  _Antialias;
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

                // float k = (_StartEnd.y - _StartEnd.w) / (_StartEnd.x - _StartEnd.z);
                // float b = _StartEnd.y - k * _StartEnd.x;

                // float d = abs(k * i.uv.x - i.uv.y + b) / sqrt(k * k + 1);
                // float t = smoothstep(_Width / 2.0 , _Width / 2.0 + _Antialias ,  d);

                //使用hlsl封装函数替换
                FinalColor = Line(_StartEnd.xy , _StartEnd.zw , _Width ,_Antialias , i.uv);

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
