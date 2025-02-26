Shader "Art_URP/FunctionTest/MoveAlongNormal"
{
    Properties
    {
        // _MainTex ("Texture", 2D) = "white" {}
        _MainColor("MainColor" , Color) = (1,1,1,1)
        _OutlineColor("OutlineColor" , Color) = (1,1,1,1)
        _OutLineWidth("OutlineWidth" , Range(0.0,0.1)) = 0.05
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        LOD 100

        //MainColor
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
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
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
            };
            
            // TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            
            CBUFFER_START(UnityPerMaterial)
                // float4 _MainTex_ST;
                float4 _MainColor;
                float4 _OutlineColor;
                float  _OutLineWidth;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                // o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                // half4 mainMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                half4 FinalColor = _MainColor;
                return FinalColor;
            }
            ENDHLSL
        }

        //Outline
        Pass
        {
            Tags { "LightMode" = "SRPDefaultUnlit" }
            Cull Front
            ZWrite On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
            };
            
            
            CBUFFER_START(UnityPerMaterial)
                float4 _OutlineColor;
                float  _OutLineWidth;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                v.positionOS.xyz += v.normalOS * _OutLineWidth;

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor = _OutlineColor;
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
