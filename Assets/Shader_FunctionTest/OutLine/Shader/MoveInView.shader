Shader "Art_URP/FunctionTest/MoveInView"
{
    Properties
    {
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
            
            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainColor;
                float4 _OutlineColor;
                float  _OutLineWidth;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
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
                float  _Factor;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);

                float3 normal = TransformObjectToWorldNormal(v.normalOS);
                //只用与屏幕位置有关的xy分量来偏移从而使轮廓大小与摄像机的位置无关
                float2 offset = TransformWorldToHClipDir(normal).xy;

                o.positionHCS.xy += offset * o.positionHCS.w * _OutLineWidth;

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
