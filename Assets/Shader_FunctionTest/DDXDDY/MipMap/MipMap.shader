Shader "Art_URP/FunctionTest/UnlitOpaque"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        [Toggle(_OPEN_MIPMAP_ON)]_OpenMipMap("OpenMipMap",Float) = 1
        _MipMapLevel("MipMapLevel" , Integer) = 0
        
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

            #pragma shader_feature _OPEN_MIPMAP_ON
            
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
                float  _MipMapLevel;    //MipMap等级
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

                #if _OPEN_MIPMAP_ON
                    half4 baseMap = SAMPLE_TEXTURE2D_GRAD(_MainTex,sampler_MainTex , i.uv , ddx(i.uv) , ddy(i.uv));
                #else
                    //默认情况下，会计算mipmap等级
                    // half4 baseMap = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex , i.uv);
                    half4 baseMap = SAMPLE_TEXTURE2D_LOD(_MainTex,sampler_MainTex , i.uv , _MipMapLevel);
                #endif
                
                FinalColor = baseMap;
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
