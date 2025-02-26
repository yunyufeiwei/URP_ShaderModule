Shader "Art_URP/FunctionTest/Glass"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode ("CullMode", float) = 2
        [Enum(Off, 0, On, 1)]_ZWriteMode ("ZWriteMode", float) = 0

        _ReflectionTex ("Reflection Texture", 2D) = "white" { }
        _RefractionTex ("Reflection Texture", 2D) = "white" { }

        _RefractColor ("Refract Color", Color) = (1, 1, 1, 1)
        _RefractIntensity ("Refract Intensity", Range(0, 1)) = 0.5

        _RefractThreshold ("Refract Threshold", Range(0, 1)) = 0.5
        _RefractSmooth ("Refract Smooth", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Transparent" "RenderType" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull [_CullMode]
        ZWrite [_ZWriteMode]

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/ShaderLibs/Node.hlsl"
            #include "Assets/ShaderLibs/MF_ColorBlendMode.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 texcoord : TEXCOORD0;
            };
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : NORMAL;
                float3 viewWS : TEXCOORD1;
                float3 positionWS : TEXCOORD2;

            };

            TEXTURE2D(_ReflectionTex);SAMPLER(sampler_ReflectionTex);
            TEXTURE2D(_RefractionTex);SAMPLER(sampler_RefractionTex);
            CBUFFER_START(UnityPerMaterial)
                half4 _RefractColor;
                half _RefractIntensity;
                half _RefractThreshold;
                half _RefractSmooth;
            CBUFFER_END
            
            Varyings vert(Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.viewWS = GetWorldSpaceViewDir(o.positionWS);
                
                // matcap uv
                float3 viewnormal = TransformWorldToViewDir(o.normalWS);
                float3 viewPos = normalize(TransformWorldToView(o.positionWS));
                viewPos = normalize(viewPos);
                float3 vcn = cross(viewPos, viewnormal);
                float2 uv = float2(-vcn.y, vcn.x);
                o.uv = uv * 0.5 + 0.5;

                return o;
            }
            half4 frag(Varyings i) : SV_Target
            {
                float3 N = normalize(i.normalWS);
                float3 V = normalize(i.viewWS);
                float NdotV = dot(N, V);
                
                // 反射
                float3 reflectColor = SAMPLE_TEXTURE2D(_ReflectionTex, sampler_ReflectionTex ,i.uv);
                
                // 折射
                //   float fresnel = 1 - smoothstep(0, 1, NdotV);
                float fresnel = 1 - SmoothValue(NdotV, _RefractThreshold, _RefractSmooth);
                
                float refractIntensity = fresnel * _RefractIntensity;
                float2 refractUV = i.uv + refractIntensity;

                float3 refractColor = SAMPLE_TEXTURE2D(_RefractionTex , sampler_RefractionTex , refractUV) * _RefractColor;
                float3 refractColor2 = _RefractColor * 0.5f;

                refractColor = lerp(refractColor2, refractColor, saturate(refractIntensity));
                // 最终颜色
                half3 resColor = reflectColor + refractColor;

                // Alpha
                half alpha = saturate(max(reflectColor.r, fresnel));

                return half4(resColor, alpha);
            }
            ENDHLSL
        }
    }
}

