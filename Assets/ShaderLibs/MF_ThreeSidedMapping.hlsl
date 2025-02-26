#ifndef MF_THREESIDEDMAPPING_INCLUDED   
#define MF_THREESIDEDMAPPING_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

//使用三面映射，输出一张灰度图
float3 TriplanarMapping_Texture_Uinty(float3 worldPosition , float3 worldNormal , Texture2D _texture , SamplerState sampler_Texture , float tile , float contrast)
{
    //计算世界空间下的uv
    half3 worldSpaceUV = ((worldPosition - TransformObjectToWorld(half3(0,0,0)))  / 100 ) * tile;
    half2 TriPlane_RG = worldSpaceUV.xy;
    half2 TriPlane_GB = worldSpaceUV.yz;
    half2 TriPlane_RB = worldSpaceUV.xz;
    half3 TriPlaneTex_RG = SAMPLE_TEXTURE2D(_texture,sampler_Texture , TriPlane_RG);
    half3 TriPlaneTex_GB = SAMPLE_TEXTURE2D(_texture,sampler_Texture , TriPlane_GB);
    half3 TriPlaneTex_RB = SAMPLE_TEXTURE2D(_texture,sampler_Texture , TriPlane_RB);
    half3 contrastVal = pow(abs(worldNormal), contrast);
    half3 weight = contrastVal / (contrastVal.x + contrastVal.y + contrastVal.z);
    
    half3 OutTriPlanarTexture = ((TriPlaneTex_RG * weight.z) + (TriPlaneTex_GB * weight.x) + (TriPlaneTex_RB * weight.y)).r;

    return OutTriPlanarTexture;
}

//使用三面映射，输出一张法线贴图
float3 TriplanarMapping_NormalTexture_Unity(float3 worldPosition , float3 worldNormal , Texture2D _texture , SamplerState sampler_Texture , float tile , half contrast)
{
    //计算世界空间下的uv
    half3 worldSpaceUV = ((worldPosition - TransformObjectToWorld(half3(0,0,0)))  / 100 ) * tile;
    half2 TriPlane_RG = worldSpaceUV.xy;
    half2 TriPlane_GB = worldSpaceUV.yz;
    half2 TriPlane_RB = worldSpaceUV.xz;

    half3 normalMapTS_RG = UnpackNormal(SAMPLE_TEXTURE2D(_texture , sampler_Texture , TriPlane_RG)).rgb;
    half3 normalMapTS_GB = UnpackNormal(SAMPLE_TEXTURE2D(_texture , sampler_Texture , TriPlane_GB)).rgb;
    half3 normalMapTS_RB = UnpackNormal(SAMPLE_TEXTURE2D(_texture , sampler_Texture , TriPlane_RB)).rgb;

    half3 contrastVal = pow(abs(worldNormal) , contrast);
    half3 weight = contrastVal/(contrastVal.x + contrastVal.y + contrastVal.z);

    half3 OutTriPlanarNormalTexture = normalMapTS_RG * weight.z + normalMapTS_GB * weight.x + normalMapTS_RB * weight.y;
    OutTriPlanarNormalTexture = normalize(half3(worldNormal.x + OutTriPlanarNormalTexture.x , worldNormal.y + OutTriPlanarNormalTexture.y , worldNormal.z));

    return OutTriPlanarNormalTexture;
}

float3 TriplanarMapping_Texture_Unreal(float3 worldPosition , float3 worldNormal , Texture2D _texture , SamplerState sampler_Texture , float tile , float contrast)
{
    half3 worldSpaceUV = ((worldPosition - TransformObjectToWorld(half3(0,0,0)))/100)  * abs(tile);
    half2 TriPlane_RG = worldSpaceUV.xy;
    half2 TriPlane_GB = worldSpaceUV.yz;
    half2 TriPlane_RB = worldSpaceUV.xz;
    half3 TriPlaneTex_RG = SAMPLE_TEXTURE2D(_texture,sampler_Texture , TriPlane_RG);
    half3 TriPlaneTex_GB = SAMPLE_TEXTURE2D(_texture,sampler_Texture , TriPlane_GB);
    half3 TriPlaneTex_RB = SAMPLE_TEXTURE2D(_texture,sampler_Texture , TriPlane_RB);

    half r = pow(abs(worldNormal.r) , contrast);
    half b = pow(abs(worldNormal.b) , contrast);

    half3 OutTriPlanarTexture = lerp(lerp(TriPlaneTex_RB , TriPlaneTex_GB , r) , TriPlaneTex_RG , b);
    
    return OutTriPlanarTexture;
}

float3 TriplanarMapping_NormalTexture_Unreal()
{

}

//CheapContrast--廉价对比度(类似Power，但比Power要便宜)
float CheapContrast(float Grayscale , float Scale)
{
    return clamp(0.0,1.0,lerp((0 - Scale) , (Scale + 1) , Grayscale)).r;
}

#endif 