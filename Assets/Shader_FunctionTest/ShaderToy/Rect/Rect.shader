Shader "Unlit/NewUnlitShader"
{
    Properties
    {
        _LeftPosition("LeftPosition",float) = -0.2
        _RightPosition("RightPosition",float) = 0.2
        _ButtomPosition("ButtomPosition",float) = -0.3
        _TopPosition("TopPosition",float) = 0.3
        _Blur("Blur",float) = 0.01
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" "RenderType" = "Transparent" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attribute
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct Varying
            {
                float2 uv : TEXCOORD0;
                float4 positionHCS : SV_POSITION;
                float2 screenUV : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                float  _LeftPosition;
                float  _RightPosition;
                float  _ButtomPosition;
                float  _TopPosition;
                float  _Blur;
            CBUFFER_END

            float Band(float2 uvDir, float startPos, float endPos, float blur)
            {
                float step1 = smoothstep(startPos-blur,startPos+blur,uvDir.x);
                float step2 = smoothstep(endPos+blur,endPos-blur,uvDir.x);
                return step1 * step2;
            }

            float Rect(float2 uvDir , float left, float right, float buttom, float top, float blur)
            {
                float band1 = Band(uvDir.x, left, right, blur);
                float band2 = Band(uvDir.y, buttom, top, blur);
                
                return band1 * band2 ;
            }

            Varying vert (Attribute v)
            {
                Varying o=(Varying)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                return o;
            }

            half4 frag (Varying i) : SV_Target
            {
                half4 FinalColor;
                float2 screenUV = i.positionHCS.xy/_ScreenParams.xy;
                screenUV.y = 1- screenUV.y;
                screenUV -= 0.5;
                screenUV.x *= _ScreenParams.x/_ScreenParams.y;
             
                 float mask = Rect(screenUV,_LeftPosition,_RightPosition,_ButtomPosition,_TopPosition,_Blur);

                FinalColor = half4(mask.xxx,1.0);
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
