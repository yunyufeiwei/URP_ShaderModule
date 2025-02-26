Shader "Art_URP/FunctionTest/MultiConcentricCircle"
{
    Properties
    {
        _Center("Center (XY)", Vector) = (0.5, 0.5, 0, 0) //只用到XY分量，且需要是[0, 1]
		_Radius("Radius", int) = 5
		_Num("Num", Float) = 4
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
                float4 _Center;
                float  _Radius;
                float  _Num;
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

                half2 uvNum = frac(i.uv * _Num);    //计算多个uv纹理
                half  uvDistance = distance(uvNum , _Center.xy);   //使用中心点和uv采样进行就距离衰减
                uvDistance = frac(uvDistance * _Radius);

                FinalColor = uvDistance.rrrr;

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
