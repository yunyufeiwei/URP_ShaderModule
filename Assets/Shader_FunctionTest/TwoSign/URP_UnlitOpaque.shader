Shader "ShaderReference/Template/UnlitOpaque"
{
    Properties
    {
        _MaskMap("MaskMap",2D) = "white"{}
        _FrontFace("Front" , Color) = (1,0,0,1)
        _BackFace("BaceFace",Color) = (0,1,0,1)
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" }
        Cull Off
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
                float3 normalOS     : NORMAL;
                float2 texcoord     : TEXCOORD;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD;
                float3 normalWS     : TEXCOORD1;
                float3 viewWS       : TEXCOORD2;
            };

            TEXTURE2D(_MaskMap);SAMPLER(sampler_MaskMap);
            CBUFFER_START(UnityPerMaterial)
                float4 _MaskMap_ST;
                float4 _FrontFace;
                float4 _BackFace;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings) 0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS.xyz);

                o.positionHCS = vertexInput.positionCS;
                o.normalWS = normalInput.normalWS;
                o.viewWS = GetWorldSpaceViewDir(v.positionOS.xyz);

                o.uv = v.texcoord;
                
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                half4 maskMap = SAMPLE_TEXTURE2D(_MaskMap,sampler_MaskMap , i.uv);

                half3 worldNormal = normalize(i.normalWS);
                half3 worldView = normalize(i.viewWS);

                float sideFace = dot( worldNormal , worldView );
				float SignFace = (1.0 + (sign( sideFace ) - -1.0) * (0.0 - 1.0) / (1.0 - -1.0));

                clip(maskMap.a - 0.01);
                FinalColor = lerp(_FrontFace , _BackFace , SignFace);
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
