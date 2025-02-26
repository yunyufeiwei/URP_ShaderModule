Shader "Art_URP/FunctionTest/Rect"
{
    Properties
    {
        _Border ("Border", Vector) = (1, 1, 1, 1)
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
                float4 _Border;
            CBUFFER_END

            // half Rect(float4 border , float2 uv)
            // {
            //     half v1 = step(border.x , uv.x);
            //     half v2 = step(border.y , 1 - uv.x);
            //     half v3 = step(border.z , uv.y);
            //     half v4 = step(border.w , 1 - uv.y);

            //     return v1 * v2 * v3 * v4;
            // }
      
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

                // half rect = Rect(_Border , i.uv);

                half rect = Rect(_Border , i.uv);
                FinalColor = half4(rect.rrr , 1.0);

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
