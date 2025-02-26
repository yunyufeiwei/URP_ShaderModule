Shader "Art_URP/Base/Light/LightMap"
{
    Properties
    {
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

            //如果要使用烘焙贴图，需要使用LIGHTMAP_ON开关
            #pragma multi_compile _ LIGHTMAP_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS     : POSITION;
                float3 normalOS       : NORMAL;
                float2 lightmapUV     : TEXCOORD1;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 normalWS     : TEXCOORD0;
                float2 lightmapUV   : TEXCOORD1;
            };
            
            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                //---\Library\PackageCache\com.unity.render-pipelines.universal@14.0.8\ShaderLibrary\Lighting.hlsl
                //使用OUTPUT_LIGHTMAP_UV的宏定义计算lightmapuv
                o.lightmapUV = v.lightmapUV.xy * unity_LightmapST.xy + unity_LightmapST.zw;

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;
                half3 worldNormalDir = normalize(i.normalWS);
                //使用SampleLightmap采样bake和realtime的lightmap
                half3 bakeGI = SampleLightmap(i.lightmapUV,worldNormalDir);

                FinalColor = half4(bakeGI , 1);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
