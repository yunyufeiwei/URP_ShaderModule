//matCap原理介绍及应用：https://zhuanlan.zhihu.com/p/420473327
//MatCap全称MaterialCapture(材质捕获)
//MapCap的本质是将发现转换到摄像机空间，然后用发现的x和y作为uv，用该uv来作为matcap贴图的采样uv
//因为最后使用的是摄像机空间法线的xy采样，所以法线的取值范围决定了贴图的有效范围是一个圆形
//优点：不需要进行大量的光照计算，只通过简单的采样一张贴图来实现类似PBR的复杂效果
//缺点：因为是采样的一张贴图，因此当灯光改变时不会变化，看起来就像一直朝向摄像，无法与环境产生交互

Shader "Art_URP/Base/Light/MatCap"
{
    Properties
    {
        _MatCapTexture("MatCapTexture" , 2D) = "white"{}
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
                float3 normalOS         : NORMAL;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 normalVS     : TEXCOORD;
            };
            
            TEXTURE2D(_MatCapTexture);SAMPLER(sampler_MatCapTexture);

            CBUFFER_START(UnityPerMaterial)
            float4 _MatCapTexture_ST;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);

                //将模型法线从本地空间转换到世界空间
                half3 normalWS = TransformObjectToWorldNormal(v.normalOS);
                //将模型的法线从世界空间转换到试图空间，并进行区域限制
                //viewSpace空间下的法线区域是[-1,1]，而uv的区域是[0，1],因此需要进行一个 x *0.5+0.5的操作
                o.normalVS = TransformWorldToViewDir(normalWS) * 0.5 + 0.5;


                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;

                half4 matCapTexture = SAMPLE_TEXTURE2D(_MatCapTexture,sampler_MatCapTexture , i.normalVS.xy);

                FinalColor = matCapTexture;

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
