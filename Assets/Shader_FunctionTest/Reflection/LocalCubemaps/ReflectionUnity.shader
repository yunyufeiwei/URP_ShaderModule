Shader "Art_URP/FunctionTest/ReflectionUnity"
{
    Properties
    {
        _Roughness ("Roughness", Range(0, 1)) = 0.1
        _MaskSize ("Mask Size", Vector) = (10, 10, 10, 1)
        _MaskSmoothness ("MaskSmoothness", Range(0.01, 1)) = 0.1
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalRenderPipeline" "RenderType" = "Opaque" "Queue" = "Geometry" }

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma target 3.0

            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets\ShaderLibs\Node.hlsl"

            

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };
            struct Varyings
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : NORMAL;
                float3 positionWS : TEXCOORD1;
                float3 viewWS : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
                half _Roughness;
                half _MaskSmoothness;
                half3 _MaskSize;
            CBUFFER_END
            
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.pos = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.viewWS = GetWorldSpaceViewDir(o.positionWS);
                return o;
            }
            half4 frag(Varyings i) : SV_Target
            {
                // float3 size = abs(unity_SpecCube0_BoxMax - unity_SpecCube0_BoxMin);

                float3 reflUVW = reflect(-i.viewWS, i.normalWS);
                half mip = PerceptualRoughnessToMipmapLevel(_Roughness);
                // ================================= 开启Box Projection =================================
                #if UNITY_SPECCUBE_BOX_PROJECTION
                    reflUVW = BoxProjectedCubemapDirection(reflUVW, i.positionWS, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
                #endif

                half4 rgbm = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0 , reflUVW, mip);
                float3 reflectionColor = DecodeHDREnvironment(rgbm, unity_SpecCube0_HDR);

                // ================================= Box Mask =================================
                
                float mask = 1 - BoxMask(i.positionWS, unity_SpecCube0_ProbePosition, _MaskSize, _MaskSmoothness);
                return half4(reflectionColor * mask, 1.0);
            }
            ENDHLSL
        }
    }
}
