Shader "Art_URP/FunctionTest/UnlitOpaque"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _DDXDDYIntensity("DDXDDYIntensity",Range(0,10)) = 2
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
            };

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            CBUFFER_START(UnityPerMaterial)
                float4  _MainTex_ST;
                float  _DDXDDYIntensity;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings) 0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);

                o.positionHCS = vertexInput.positionCS;
                
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                half4 baseMap = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex , i.uv);

                baseMap += ddx(baseMap) * _DDXDDYIntensity + ddy(baseMap) * _DDXDDYIntensity;

                FinalColor = baseMap;
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
