Shader "Art_URP/Base/Light/ReflectionProbe"
{
    Properties
    {
        _Smoothness("Smoothness",Range(0,1)) = 1.0
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}
        LOD 100

        pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS     : POSITION;
                float3 normalOS       : NORMAL;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 normalWS     : TEXCOORD1;
                float3 viewWS       : TEXCOORD2;
            };
            
            CBUFFER_START(UnityPerMaterial)
            float _Smoothness;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS    = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS       = TransformObjectToWorldNormal(v.normalOS);
                o.viewWS         = GetWorldSpaceViewDir(positionWS);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;
                half3 worldNormalDir = normalize(i.normalWS);
                half3 worldViewDir = normalize(i.viewWS);

                half roughness = 1 - _Smoothness;
                //因为粗糙度和mipmap的LOD关系在真实情况下不是线性的，所以使用这个函数来计算
                //Library\PackageCache\com.unity.render-pipelines.core@14.0.8\ShaderLibrary\ImageBasedLighting.hlsl
                half mip = PerceptualRoughnessToMipmapLevel(roughness);
                float3 reflectVector = reflect(-worldViewDir , worldNormalDir);
                half3 hdrEnv = DecodeHDREnvironment(SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector, mip), unity_SpecCube0_HDR);

                FinalColor = half4(hdrEnv ,1);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
