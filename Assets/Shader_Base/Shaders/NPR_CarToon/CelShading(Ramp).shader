//NPR (Non-photorealistic rendering) 非真实感渲染，范围很大，卡通只是其中一种，其它例如 素描、水墨、水彩等等
//Cel Shading 又称赛璐璐渲染，是一种(NPR),一种日式卡通风格，其特点就是减少色阶

//因为色阶变化一点，其实就会很明显的体现出来，而主要风格由美术决定，所以最好的办法就是用Ramp纹理或者说是一个查询表
//把原先Phong或者Blinn-Phong着色中的漫反射和高光，重新在Ramp纹理上采样，Ramp是一个降梯度后的图片，使用起来比较灵活

////渲染过程分为着色、外描边、边缘光、高光
//注意常见的几个Ramp纹理Hard、Soft、3level，都是为了适配Lambert漫反射的映射画出来的，记得把图片的Wrap Mode改为Clamp否则采样到边缘的时候会有误差

//参考说明：
//https://zhuanlan.zhihu.com/p/110025903

Shader "Art_URP/Base/NPR/CelShading-Ramp"
{
    Properties
    {
        [NoScaleOffset]_RampMap("RampMap" , 2D) = "white"{}
        _Color("Color",Color) = (1,1,1,1)
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
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS     : POSITION;
                float3 normalOS       : NORMAL;
                float2 texcoord       : TEXCOORD;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD;
                float3 normalWS     : TEXCOORD1;
                float3 viewWS       : TEXCOORD2;
            };
            
            TEXTURE2D(_RampMap);SAMPLER(sampler_RampMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _RampMap_ST;
                float4 _Color;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.viewWS = GetWorldSpaceViewDir(positionWS);

                o.uv = TRANSFORM_TEX(v.texcoord , _RampMap);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;
                Light light = GetMainLight();
                half3 lightColor = light.color * light.distanceAttenuation;
                half3 lightDir = light.direction;

                half3 worldNormalDir = normalize(i.normalWS);
                half3 worldViewDir = normalize(i.viewWS);

                //Lambert
                half lambert = saturate(dot(worldNormalDir,lightDir));
                half2 rampUV = half2(lambert,lambert);
                //使用lambert得到的[0-1]的范围作为Ramp贴图采样的uv，所以Ramp纹理左边最黑的地方也就是背光面，最后边也是最亮的地方，就是向光面
                half4 baseMap = SAMPLE_TEXTURE2D(_RampMap , sampler_RampMap , rampUV);

                FinalColor = baseMap * _Color;

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
