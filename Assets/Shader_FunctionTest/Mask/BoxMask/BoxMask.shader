Shader "Art_URP/FunctionTest/BoxMask"
{
    Properties
    {
        _MaskCenter ("Box Mask Center", Vector) = (0, 0, 0, 1)
        _MaskSize ("Box Mask Size", Vector) = (1, 1, 1, 1)
        _Falloff ("Falloff", Range(0, 1)) = 0.1
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
                float4 vertex : POSITION;
            };
            struct Varyings
            {
                float4 pos : SV_POSITION;
                float3 positionWS : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                float3 _MaskCenter;
                float3 _MaskSize;
                float _Falloff;
            CBUFFER_END
            
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.pos = TransformObjectToHClip(v.vertex);
                o.positionWS = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }
            
            half4 frag(Varyings i) : SV_Target
            {
                float mask = BoxMask(i.positionWS, _MaskCenter, _MaskSize, _Falloff);
                return mask;
            }
            ENDHLSL
        }
    }
}