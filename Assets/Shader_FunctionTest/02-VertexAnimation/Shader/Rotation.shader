Shader "Art_URP/FunctionTest/Rotation"
{
    Properties
    {
        _RotateVector("RotateVector", Vector) = (0,0,0,0)
        [PowerSlider(3.0)]_Angle("Angle", Range (-90, 90)) = 0
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" }
        Cull Off

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _RotateVector;
                float _Angle;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                float s,c;
                sincos(radians(-_Angle),s,c);
                
                float4x4 rotateMatrix_X =
                {			
                    1,0,0, 0,
                    0,c,-s,0,
                    0,s,c, 0,
                    0,0,0, 1
                };
                float4x4 rotateMatrix_Y =
                {			
                    c,0,s, 0,
                    0,1,0,0,
                    -s,0,c, 0,
                    0,0,0, 1
                };
                float4x4 rotateMatrix_Z =
                {			
                    c,-s,0,0,
                    s,c,0,0,
                    0,0,1,0,
                    0,0,0,1
                };
                float offset = 0.5f;

                v.positionOS += float4(0,offset,0,0);
                float4x4 matrixm = mul(rotateMatrix_X,rotateMatrix_Y);
                v.positionOS.xyz = mul(matrixm,v.positionOS).xyz;
                v.positionOS += float4(0,-offset,0,0);

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                return 1;
            }
            ENDHLSL
        }
    }
}
