Shader "Art_URP/FunctionTest/UniversalMask2D"
{
    Properties
    {
        _MaskCenter ("Mask Center", Vector) = (0, 0, 0, 1)
        _Intensity ("Intensity", Range(0, 10)) = 3
        _Roundness ("Roundness", Range(0, 10)) = 1
        _Smoothness ("Smoothness", Range(0, 5)) = 0.2
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
                float2 uv : TEXCOORD0;
            };
            struct Varyings
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float3 _MaskCenter;
                float _Roundness;
                float _Intensity;
                float _Smoothness;
            CBUFFER_END
            
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.pos = TransformObjectToHClip(v.vertex);
                o.uv = v.uv;
                return o;
            }
            half4 frag(Varyings i) : SV_Target
            {
                float mask = UniversalMask2D(i.uv, _MaskCenter, _Intensity, _Roundness, _Smoothness);
                return mask;
            }
            ENDHLSL
        }
    }
}