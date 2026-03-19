#ifndef UNIVERSAL_ManualBRDF_INCLUDED
#define UNIVERSAL_ManualBRDF_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

// 将感知粗糙度转换为几何粗糙度 (匹配 Lit.shader)
float CustomPerceptualRoughnessToRoughness(float perceptualRoughness)
{
    return perceptualRoughness * perceptualRoughness;
}

//Specular Item
//D项---法线分布函数GGX (Trowbridge-Reitz)
float Custom_D_GGX(float NdotH, float roughness)
{
    float a = roughness * roughness;
    float a2 = a * a * a;
    float NdotH2 = NdotH * NdotH;

    float nom = a2;
    float denom = (a2 - 1) * NdotH2 + 1.0;
    denom = PI * denom * denom;
    
    return SafeDiv(nom, denom);
}

// G项辅助函数 - 几何遮蔽Schlick-GGX
float Custom_GeometrySchlickGGX(float NdotV , float roughness)
{
    float a = roughness + 1.0;
    float a2 = (a * a) / 8.0;
    float nom = NdotV;
    
    float denom = NdotV * (1.0 - a2) + a2;
    return nom / max(denom, 0.0001);
}
// G项 - 几何遮蔽函数Smith
float Custom_GeometrySmith(float NdotV, float NdotL, float roughness)
{
    float GGXNdotV = Custom_GeometrySchlickGGX(NdotV, roughness);
    float GGXNdotL = Custom_GeometrySchlickGGX(NdotL, roughness);
    return GGXNdotV * GGXNdotL;
}

// F项 - 菲涅尔Schlick近似
//F(θ) = F₀ + (F₉₀ - F₀) * (F₉₀ - cosθ)⁵, 其中cosθ = 通常用 (v·h) 或 (n·v) 计算
//F(n·l) = F₀ + (F₉₀ - F₀) * (F₉₀ - n·l)⁵, 对于大多数材质 F₉₀ = 1.0（掠射角时几乎所有材质都100%反射）
//因此公式可以简化为 F(n·l) = F₀ + (1 - F₀) * (1 - n·l)⁵
half3 Custom_F_FresnelSchlick(float VdotH, half3 F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);
}

// F项 - 带粗糙度的菲涅尔（用于间接光）
float3 Custom_FresnelSchlickRoughness(float3 N, float3 V, float3 F0, float roughness)
{
    float NdotV = max(saturate(dot(N,V)), 0.0001);
    float smoothness = 1.0 - roughness;
    return F0 + (max(float3(smoothness, smoothness, smoothness), F0) - F0) * pow((1.0 - NdotV), 5.0);
}

half3 Custom_CalculateDirectLightBRDF(Light light, half3 normalWS, half3 viewDirWS, half3 baseColor, half metallic, half roughness, half3 F0)
{
    half3 L = light.direction;
    half3 H = normalize(L + viewDirWS);

    half NdotL = max(saturate(dot(normalWS, L)), 0.0001);
    half NdotV = max(saturate(dot(normalWS, viewDirWS)), 0.0001);
    half NdotH = max(saturate(dot(normalWS, H)), 0.0001);
    half VdotH = saturate(dot(H, viewDirWS));

    // 计算镜面反射
    float D = Custom_D_GGX(NdotH, roughness);
    float G = Custom_GeometrySmith(NdotV, NdotL, roughness);
    half3 F = Custom_F_FresnelSchlick(VdotH, F0);
    half3 specularBRDF = (D * G * F) / max(4.0 * NdotL * NdotV, 0.0001);


    half3 kS = F;
    half3 kD = (1.0 - kS) * (1.0 - metallic);

    half3 diffuseBRDF = kD * baseColor;

    half3 result = (diffuseBRDF + specularBRDF) * light.color * light.distanceAttenuation * light.shadowAttenuation * NdotL;
                
    return result;
}

#endif
