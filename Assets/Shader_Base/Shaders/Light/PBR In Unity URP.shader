//Unity URP中的PBR实现

//PBR相关资料：
//https://zhuanlan.zhihu.com/p/460992505  unity3D里使用的PBR公式
//https://inst.cs.berkeley.edu/~cs283/sp13/lectures/cookpaper.pdf
//https://zhuanlan.zhihu.com/p/370343129  Cook-Torrance
//https://zhuanlan.zhihu.com/p/369142810  辐射度量学、BRDF、反射方程、渲染方程、蒙特卡洛积分

//https://www.jordanstevenstechart.com/physically-based-rendering

//cook-torrance反射方程 = D(h)F(v,h)G(l,v,h) / 4(N ⋅ L)(N ⋅ V)
//D：(Normal Distribution Function简称NDF)微表面的法线分布函数---D = roughness^2 / PI*( NoH^2 * (roughness^2 - 1) + 1 )^2  //Trowbridge-Reitz GGX
//F：菲尼尔发射函数---------它可以告诉我们每个活跃的微面元会把多少反射光线反射到观察方向上，即反射光线占入射光线的比例。
//G：几何阴影函数  ---------它给出了活跃的微面元所占的比例，只有活跃的微面元才会把光线反射到观察方向上。

//其中分子 G/4(wo ⋅ n)(wi ⋅ n) 又常作为可见项V (Visibility)   --https://community.arm.com/cfs-file/__key/communityserver-blogs-components-weblogfiles/00-00-00-20-66/siggraph2015_2D00_mmg_2D00_renaldas_2D00_slides.pdf
//V = G(N⋅V , N⋅L , roughness) / 4(N⋅V)(N⋅L)   优化版：V = 1/(LoH)^2 * (1-roughness^2)+roughness^2 * 4


Shader "Art_URP/Base/Light/PBR In Unity URP"
{
    Properties
    {
        _Albedo("Albedo",Color) = (1,1,1,1)
        _Metallic("Metallic",Range(0,1)) = 0.5
        _Roughness("Roughness",Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline""RenderType" = "Opaque"  "Queue" = "Geometry"}
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
                float3 normalWS     : TEXCOORD0;
                float3 viewWS       : TEXCOORD1;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 _Albedo;
                float _Metallic;
                float _Roughness;
            CBUFFER_END

            //D项 Normal Distribution Function ： Trowbridge-Reitz NDF算法，与GGX算法类似
            //D = roughness^2 / PI*( NoH^2 * (roughness^2 - 1) + 1 )^2  //Trowbridge-Reitz GGX
            half D_GGX_TR(half3 N , half3 H , half roughness)
            {
                half a = roughness;
                half a2 = a * a;
                half NdotH = max(0 , dot(N,H));
                half NdotH2 = NdotH * NdotH;

                half nom = a2;
                half denom = ((a2 - 1.0) * NdotH2 + 1.0);
                denom = PI * denom * denom;
                return nom/denom;
            }

            //Unity近似实现的V * F 项 ：V * F = 1/((LoH)^2 * (roughness + 0.5)) * specularColor
            half ApproximateVF(half3 L, half3 H , half roughness)
            {
                half LH = saturate(dot(L,H));
                half denom = max(0.1h , (LH*LH)*(roughness + 0.5)) ;
                return 1/denom;
            }

            half3 LightPBR_URP(half3 albedo , half3 lightColor , half3 lightDirWS , half3 normalWS , half3 viewDirWS , half metallic , half perceptualRoughness)
            {
                half3 H = SafeNormalize(lightDirWS + viewDirWS);
                half NdotL = saturate(dot(normalWS , lightDirWS));

                half roughness = max(perceptualRoughness*perceptualRoughness , HALF_MIN_SQRT);

                half3 dielectricSpec = 0.04;
                half oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
                half reflectivity = 1.0 - oneMinusReflectivity;

                half3 brdfSpecular = lerp(dielectricSpec, albedo, metallic);

                half D = D_GGX_TR(normalWS,H,roughness);
                half VF = ApproximateVF(lightDirWS,H,roughness);

                half nominator = D * VF;
                half denominator = 4;
                half3 specularTerm = nominator / denominator * brdfSpecular;

                half3 diffuseTerm = albedo * oneMinusReflectivity / PI;
                half3 radiance = lightColor * NdotL;

                half3 brdf = PI * (diffuseTerm + specularTerm) * radiance;

                half3 ambientColor = unity_AmbientSky.rgb * albedo;

                return brdf + ambientColor;
            }


            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS , true);
                o.viewWS = GetWorldSpaceViewDir(positionWS);

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

                half3 pbr = LightPBR_URP(_Albedo.rgb , lightColor , lightDir , worldNormalDir ,worldViewDir , _Metallic , _Roughness);
                FinalColor = half4(pbr,1);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
