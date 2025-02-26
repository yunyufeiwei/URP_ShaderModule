//参考文章：https://zhuanlan.zhihu.com/p/550276036
//Minnaert照明模型最初设计用于模拟月球的着色，因此它通常被称为moon shader
//Minnaert适合模拟多孔或纤维状表面，如月球或天鹅绒。这些表面会导致大量光线反向散射
//这一点在纤维主要垂直于表面（如天鹅绒、天鹅绒甚至地毯）的地方尤为明显。此模拟提供的结果与Oren Nayar非常接近，后者也经常被称为velvet（天鹅绒）或moon着色器。

Shader "Art_URP/Base/Light/Minnaert"
{
    Properties
    {
        _Roughness("Roughness",Range(0.01,8)) = 1
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
                float3 normalWS     : TEXCOORD;
                float3 viewWS       : TEXCOORD1;
            };
            
            CBUFFER_START(UnityPerMaterial)
            float _Roughness;
            CBUFFER_END

            half LightingMinnaert(half3 lightDirWS , half3 normalWS , half3 viewDirWS , half roughness)
            {
                float NdotL = max(0,dot(normalWS,lightDirWS));
                float NdotV = max(0,dot(normalWS,viewDirWS));
                float minnaert = saturate(NdotL * pow(NdotL * NdotV , roughness));

                return minnaert;
            }

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);

                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.viewWS   = GetWorldSpaceViewDir(positionWS);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;

                Light light = GetMainLight();
                half3 lightColor = light.color;
                half3 worldLightDir = light.direction;
                half3 worldNormalDir = normalize(i.normalWS);
                half3 worldViewDir = normalize(i.viewWS);

                half  minnaert = LightingMinnaert(worldLightDir , worldNormalDir , worldViewDir , _Roughness);
                half3 minnaertColor = minnaert * lightColor;

                FinalColor = half4(minnaertColor , 1);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
