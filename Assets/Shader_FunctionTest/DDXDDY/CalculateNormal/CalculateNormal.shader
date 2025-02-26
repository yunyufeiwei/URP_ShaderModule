Shader "Art_URP/FunctionTest/CalculateNormal"
{
    Properties
    {
        _BaseMap ("BaseMap", 2D) = "white" {}
        [Toggle(_DDXDDY_ON)]_DDXDDY("DDXDDY",Integer) = 1
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature _DDXDDY_ON
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD;
                float3 positionWS   : TEXCOORD1;
            };

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings) 0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);

                o.positionWS = vertexInput.positionWS;
                o.positionHCS = vertexInput.positionCS;
                
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;
                half3 normalColor = normalize(i.positionWS);

                #if _DDXDDY_ON
                    normalColor = normalize(cross(ddy(i.positionWS) , ddx(i.positionWS)));
                #endif

                FinalColor = half4(normalColor , 1.0f);
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
