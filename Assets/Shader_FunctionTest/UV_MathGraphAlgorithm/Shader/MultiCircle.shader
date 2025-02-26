Shader "Art_URP/FunctionTest/MultiCircle"
{
    Properties
    {
        _Center ("Center (XY)", Vector) = (0.5, 0.5, 0, 0) //只用到XY分量，且需要是[0, 1]
        _Radius ("Radius", Range(0, 1)) = 0.3
        _Num ("Num", Float) = 10
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
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
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

                half2 uvNum = frac(i.uv * _Num);

                FinalColor = Circle(_Center.xy , _Radius , uvNum).rrrr;

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
