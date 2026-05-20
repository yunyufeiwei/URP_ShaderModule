
#ifndef _RF_BRDF_CGINC_
#define _RF_BRDF_CGINC_

inline float Pow5(float x)
{
    return x * x * x * x * x;
}

inline float Pow4(float x)
{
    return x * x * x * x ;
}

inline float3 Unity_SafeNormalize(float3 inVec)
{
	float dp3 = max(1e-7f, dot(inVec, inVec));
	return inVec * rsqrt(dp3);
}

inline float3 Fresnel(float3 F0, float cosA)
{
    float t = Pow5(1 - cosA);
    return F0 + (1 - F0) * t;
}

inline float3 FresnelLerp(float3 F0, float3 F90, float cosA)
{
    float t = Pow5(1 - cosA); 
    return lerp(F0, F90, t);
}

inline float3 FresnelLerpFast(float3 F0, float3 F90, float cosA)
{
	float t = Pow4(1 - cosA);
	return lerp(F0, F90, t);
}

inline float DisneyDiffuse(float nv, float nl, float lh, float perceptualRoughness)
{
    float fd90 = 0.5 + 2 * lh * lh * perceptualRoughness;
    float lightScatter   = (1 + (fd90 - 1) * Pow5(1 - nl));
    float viewScatter    = (1 + (fd90 - 1) * Pow5(1 - nv));

    return lightScatter * viewScatter;
}

inline float SmithJointGGXVisibility(float nl, float nv, float roughness)
{
    float a = roughness;
    float lambdaV = nl * (nv * (1 - a) + a);
    float lambdaL = nv * (nl * (1 - a) + a);

    return 0.5f / (lambdaV + lambdaL + 1e-5f);
}

inline float GGX(float nh, float roughness)
{
    float a2 = roughness * roughness;
    float d = (nh * a2 - nh) * nh + 1.0f; 
    return UNITY_INV_PI * a2 / (d * d + 1e-7f); 
}
//cloth——————————————————————————————————
 inline float FabricD (float NdotH, float roughness)
 {
  return 0.96 * (1 - NdotH)*(1 - NdotH) + 0.057; 
 }

inline float FabricScatterFresnelLerp(float nv, float scale)
{
     float t0 = Pow4 (1 - nv);
     float t1 = 0.4 * (1 - nv);
     return (t1 - t0) * scale + t0; 
}


//——————————————————————————————————————————————






inline float GGXMulPI(float nh, float roughness)
{
    float a2 = roughness * roughness;
    float d = (nh * a2 - nh) * nh + 1.0f; 
    return a2 / (d * d + 1e-7f); 
}


inline float3 BoxProjectedCubemapDirection(float3 worldRefl, float3 worldPos, float4 cubemapCenter, float4 boxMin, float4 boxMax)
{
	UNITY_BRANCH
		if (cubemapCenter.w > 0.0)
		{
			float3 nrdir = normalize(worldRefl);
			float3 rbmax = (boxMax.xyz - worldPos) / nrdir;
			float3 rbmin = (boxMin.xyz - worldPos) / nrdir;
			float3 rbminmax = (nrdir > 0.0f) ? rbmax : rbmin;
			float fa = min(min(rbminmax.x, rbminmax.y), rbminmax.z);
			worldPos -= cubemapCenter.xyz;
			worldRefl = worldPos + nrdir * fa;
		}
	return worldRefl;
}





#endif 