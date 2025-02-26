//PBR(PhysicallyBasedShading)是基于与现实世界的物理原理所创建的一种渲染技术相比于传统的基于经验的模型（Phong Blin-Phong等）更具有物理准确性但是本质还是近似模拟,所以是基于物理渲染而不是物理渲染。
//基于物理的光照模型必须满足一下三个条件:
//1.基于微平面(Microfacet)的表面模型
//2.能量守恒;
//3.基于物理的BRDF(Bidirectional Reflectance Distribution Function,双向反射分布函数)。常见Cook-Torrance BRDF模型、Ward BRDF模型等。

//参考：
//https://learnopengl-cn.github.io/07%20PBR/01%20Theory/
//https://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf
//https://www.jordanstevenstechart.com/physically-based-rendering

// Cook-Torrance模型目前常用的一种BRDF,包含漫射和镜面反射的计算部分
// Fr = Kd * lambert方程 + Ks * cook-torrance方程
// cook-torrance方程 = DFG/4(wo ⋅ n)(wi ⋅ n)

// 其中
// *D项(NDF) 法线分布函数：估算在受到表面粗糙度的影响下，法线方向与中间向量一致的微平面的数量。这是用来估算微平面的主要函数。
// *G项 几何函数：描述了微平面自成阴影的属性。当一个平面相对比较粗糙的时候，平面表面上的微平面有可能挡住其他的微平面从而减少表面所反射的光线。
// *F项 菲涅尔方程：菲涅尔方程描述的是在不同的表面角下表面所反射的光线所占的比率(不同介质之间折射和反射的比率)。
// *每一项都有很多公式可以替代
// 这里使用 D: Trowbridge-Reitz GGX; G: Smith’s Schlick-GGX; F: Fresnel-Schlick approximation;
// V: View vector  视角向量
// L: Light vector 灯光方向向量
// N: Normal vector 法线向量
// H: Half vector 半角向量 (V + L)得单位向量


Shader "Art_URP/Base/Light/PBR Common"
{
    Properties
    {
        _Albedo("Albedo",Color) = (1,1,1,1)
        _Metallic("Metallic",Range(0,1)) = 0.5
        _Roughness("Roughness",Range(0,1)) = 0.5
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
                float3 normalWS     : TEXCOORD0;
                float3 viewWS       : TEXCOORD1;
            };
            
            CBUFFER_START(UnityPerMaterial)
            float4 _Albedo;
            float  _Metallic;
            float  _Roughness;
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
            //G项 几何函数
            half GeometrySchlickGGX(half NdotV, half roughness)
            {
                float r = (roughness + 1.0);
                float k = (r*r) / 8.0;

                float nom   = NdotV;
                float denom = NdotV * (1.0 - k) + k;

                return nom / denom;
            }
            //G项 几何函数 Smith’s Schlick-GGX
            half G_GeometrySmith(half3 N , half3 V , half3 L , half roughness)
            {
                half NdotV = max(0.0 , dot(N,V));
                half NdotL = max(0.0 , dot(N,L));
                half ggx1 = GeometrySchlickGGX(NdotV,roughness);
                half ggx2 = GeometrySchlickGGX(NdotL,roughness);
                return ggx1*ggx2;
            }

            //F项
            half3 F_FresnelSchlick(half HV , half3 F0)
            {
                return F0 + (1.0 - F0) * pow(saturate(1.0 - HV), 5.0);
            }
            //这里仅仅记录一下,并未使用改函数作为F项
            half3 F_FresnelSchlickInUnrealEngine(half HV, half3 F0)
            {
               return F0 + (1.0 - F0)* exp2((-5.55473 * HV - 6.98316) * HV);
            }

            //Lighting
            //Fr = Kd * lambert方程 + Ks * cook-torrance方程
            //cook-torrance方程 = DFG/4(wo ⋅ n)(wi ⋅ n)
            half3 LightingPBR_URP(half3 albedo , half3 lgihtColor , half3 lightDirWS , half3 normalWS , half3 viewDirWS , half metallic , half roughness)
            {
                //为Cook-Torrance准备各项数据
                half3 H = SafeNormalize(lightDirWS+viewDirWS);
                half HdotV = saturate(dot(H,viewDirWS));
                half NdotV = saturate(dot(normalWS,viewDirWS));
                half NdotL = saturate(dot(normalWS,lightDirWS));

                //F0 = ((n-1)/(n+1))^2 n代表折射率 1为空气。处于简化目的，对于大多数电介质表面而言使用0.04作为基础反射率已经足够好了。
                //非金属 F0.xyz一样而金属得 F0.xyz 不一样
                half3 F0 = half3(0.04,0.04,0.4);
                F0 = lerp(F0, albedo, metallic);

                half  D = D_GGX_TR(normalWS,H,roughness);
                half3 F = F_FresnelSchlick(HdotV,F0);
                half  G = G_GeometrySmith(normalWS,viewDirWS,lightDirWS,roughness);

                half3 nominator = D * F * G;
                half  denominator = max(4 * NdotV * NdotL , 0.001);
                half3 specularTerm = nominator / denominator;

                half3 Ks = F;
                //能量守恒，漫反射和镜面反射不能高于1
                half3 Kd = 1 - Ks;
                //金属会更多的吸收折射光线导致漫反射消失，这是金属物质的特殊物理性质。
                Kd *= 1.0 - metallic;
                //漫反射项
                half3 diffuseTerm = Kd * albedo / PI;
                half3 radiance = lgihtColor * NdotL;
                half3 brdf = (diffuseTerm + specularTerm) * radiance;
                half3 ambientColor = unity_AmbientSky.rgb * albedo;
                // half3 ambientColor = _GlossyEnvironmentColor.xyz * albedo;

                return brdf + ambientColor;
            }

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
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

                half3 pbr = LightingPBR_URP(_Albedo.rgb , lightColor , lightDir , worldNormalDir , worldViewDir , _Metallic , _Roughness);

                FinalColor = half4(pbr,1);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
