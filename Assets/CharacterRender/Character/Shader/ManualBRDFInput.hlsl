#ifndef UNIVERSAL_ManualBRDFInput_INCLUDED
#define UNIVERSAL_ManualBRDFInput_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

TEXTURE2D(_BaseMap);    SAMPLER(sampler_BaseMap);
TEXTURE2D(_MaskMap);    SAMPLER(sampler_MaskMap);
TEXTURE2D(_NormalMap);  SAMPLER(sampler_NormalMap);
TEXTURE2D(_EmissiveMap);  SAMPLER(sampler_EmissiveMap);

CBUFFER_START(UnityPerMaterial)
    float4 _BaseColor;
    float4 _BaseMap_ST;
    float4 _MaskMap_ST;
    float4 _NormalMap_ST;
    float  _NormalScale;
    float  _Roughness;
    float  _OcclusionStrength;
    float4 _EmissiveColor;
    float  _EmissiveIntensity;
CBUFFER_END

#endif
