Shader "Catlikecoding/TexturedWithDetail"
{
    Properties
    {
        _Tint("Tint" , Color) = (1,1,1,1)
        _SplatTex ("SplatTex", 2D) = "white"{}
        [NoScaleOffset]_Texture1("_Texture1",2D) = "white"{}
        [NoScaleOffset]_Texture2("_Texture2",2D) = "white"{}
        [NoScaleOffset]_Texture3("_Texture3",2D) = "white"{}
        [NoScaleOffset]_Texture4("_Texture5",2D) = "white"{}
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
                float2 uvSplat      : TEXCOORD1;
            };

            TEXTURE2D(_SplatTex);SAMPLER(sampler_SplatTex);
            TEXTURE2D(_Texture1);SAMPLER(sampler_Texture1);
            TEXTURE2D(_Texture2);SAMPLER(sampler_Texture2);
            TEXTURE2D(_Texture3);SAMPLER(sampler_Texture3);
            TEXTURE2D(_Texture4);SAMPLER(sampler_Texture4);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _Tint;
                float4 _SplatTex_ST;
                float4 _Texture1_ST;
                float4 _Texture2_ST;
                float4 _Texture3_ST;
                float4 _Texture4_ST;
            CBUFFER_END

            //顶点着色器
            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings) 0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);

                o.positionHCS = vertexInput.positionCS;

                o.uv = TRANSFORM_TEX(v.texcoord , _Texture1);
                o.uvSplat = v.texcoord;
                return o;
            }

            //像素着色器
            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                half4 splatMap = SAMPLE_TEXTURE2D(_SplatTex,sampler_SplatTex , i.uvSplat);
                half4 texture1 = SAMPLE_TEXTURE2D(_Texture1,sampler_Texture1 , i.uv) * splatMap.r;
                half4 texture2 = SAMPLE_TEXTURE2D(_Texture2,sampler_Texture2 , i.uv) * splatMap.g;
                half4 texture3 = SAMPLE_TEXTURE2D(_Texture3,sampler_Texture3 , i.uv) * splatMap.b;
                half4 texture4 = SAMPLE_TEXTURE2D(_Texture4,sampler_Texture4 , i.uv) * (1 - (splatMap.r + splatMap.g + splatMap.b));

                FinalColor = texture1 + texture2 + texture3 + texture4;
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
