Shader "Catlikecoding/TexturedWithDetail"
{
    Properties
    {
        _Tint("Tint" , Color) = (1,1,1,1)
        _BaseMap ("BaseMap", 2D) = "white" {}
        _DetailTex("DetailTexture",2D) = "gray"{}
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
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            
            //顶点着色器输入结构体
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD;
            };
            //顶点着色器输出结构体
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD;
                float2 uvDetail     : TEXCOORD1;
            };

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D(_DetailTex);SAMPLER(sampler_DetailTex);
            CBUFFER_START(UnityPerMaterial)
                float4 _Tint;
                float4 _BaseMap_ST;
                float4 _DetailTex_ST;
            CBUFFER_END

            //顶点着色器
            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings) 0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);

                o.positionHCS = vertexInput.positionCS;
                
                o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
                o.uvDetail = TRANSFORM_TEX(v.texcoord , _DetailTex);
                return o;
            }

            //像素着色器
            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap , i.uv);
                baseMap *= SAMPLE_TEXTURE2D(_DetailTex,sampler_DetailTex , i.uvDetail);
                // baseMap = LinearToGamma22(baseMap);

                FinalColor = baseMap * _Tint;
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
