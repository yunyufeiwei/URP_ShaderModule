Shader "Art_URP/FunctionTest/SphereMask"
{
    Properties
    {
        _MaskCenter ("Sphere Mask Center", Vector) = (0, 0, 0, 1)
        _MaskRadius ("Sphere Mask Radius", Vector) = (1, 1, 1, 1)
        _Hardness ("Hardness", Range(0, 10)) = 5
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" }
        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/ShaderLibs/Node.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD1;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float3 _MaskCenter;
                float3 _MaskRadius;
                float _Hardness;
            CBUFFER_END
            
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);

                return o;
            }
            half4 frag(Varyings i) : SV_Target
            {
                float mask = SphereMask(i.positionWS, _MaskCenter, _MaskRadius, _Hardness);
                return mask;
            }
            ENDHLSL
        }
    }
}