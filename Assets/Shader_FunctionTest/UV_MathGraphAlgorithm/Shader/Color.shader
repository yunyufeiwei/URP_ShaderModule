Shader "Art_URP/FunctionTest/Color"
{
    Properties
    {
        _Border("Border", Vector) = (0.1,0.1,0.1,0.1)
		_CircleCenter("Circle Center", Vector) = (0.5, 0.5, 0, 0)
		_CircleRadius("Circle Radius", Range(0, 1)) = 0.3
        _Color("Color" , Color) = (1,1,1,1)
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
                float4  _Border;
                float4  _CircleCenter;
                float   _CircleRadius;
                float4 _Color;
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

                FinalColor = (Rect(_Border, i.uv) - Circle(_CircleCenter.xy, _CircleRadius, i.uv)) * _Color;

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
