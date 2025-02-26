Shader "Art_URP/FunctionTest/Plane Shadow"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
    }
    SubShader
    {
        Tags{"Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            Cull Off

            HLSLPROGRAM
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv: TEXCOORD0;
                float3 positionWS: TEXCOORD1;
                float4 positionCS: SV_POSITION;
            };

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _CenterPos;
                float  _CenterRadius;
                half   _ShadowFalloff;
                half   _HeightRange;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionWS = vertexInput.positionWS;
                o.positionCS = vertexInput.positionCS;

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            half4 frag(Varyings i): SV_Target
            {
                float3 toSphere = _CenterPos.xyz - i.positionWS;
                float  sqrDistanceXZ = dot(toSphere.xz, toSphere.xz);

                float yMask = step(toSphere.y, 0) + step(_HeightRange, toSphere.y);

                half atten = (sqrDistanceXZ / _CenterRadius) / _ShadowFalloff;

                half4 FinalColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                FinalColor *= saturate(atten + yMask);
                return FinalColor;
            }
            ENDHLSL

        }
    }
}