#ifndef UNIVERSAL_OUTLINEPASS_INCLUDED
#define UNIVERSAL_OUTLINEPASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

struct a2v
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float3 tangentOS    : TANGENT;
    float4 color        : COLOR;
};

struct v2f
{
    float4 positionHCS  : SV_POSITION;
};

CBUFFER_START(UnityPerMaterial)
    float4  _OutlineColor;
    float   _OutlineWidth;
CBUFFER_END

v2f vert (a2v v)
{
    v2f o;

    float4 nearUpperRight = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));
    float aspect = abs(nearUpperRight.y / nearUpperRight.x);
    
    //float outlineTex = SAMPLE_TEXTURE2D_LOD(_OutlineWidthTexture, float4(TRANSFORM_TEX(v.texcoord, _OutlineWidthTexture), 0, 0)).r;

    #if _USE_OUTLINE
        #if defined(MTOON_OUTLINE_WIDTH_WORLD)
            float3 offset = _OutlineWidth * v.normalOS * 0.0001;
            v.positionOS.xyz = v.positionOS.xyz + offset;
            o.positionHCS = TransformObjectToHClip(v.positionOS);
        #elif defined(MTOON_OUTLINE_WIDTH_SCREEN)
            o.positionHCS = TransformObjectToHClip(v.positionOS);
            float3 viewNormal = TransformWorldToViewNormal(TransformObjectToWorldNormal(v.normalOS.xyz));
            float3 clipNormal = TransformWViewToHClip(viewNormal);
            float2 projectedNormal = normalize(clipNormal.xy);
            projectedNormal *= min(o.positionHCS.w, 1);
            projectedNormal.x *= aspect;
            o.positionHCS.xy += 0.01 * _OutlineWidth * projectedNormal.xy;
        #elif defined(MTOON_OUTLINE_WIDTH_WORLD_VERTEX_COLOR)
            float3 offset = v.color.x * _OutlineWidth * v.normalOS * 0.0001;
            o.positionHCS = TransformObjectToHClip(v.positionOS + offset);
        #elif defined(MTOON_OUTLINE_WIDTH_SCREEN_VERTEX_COLOR)
            o.positionHCS = TransformObjectToHClip(v.positionOS);
            float3 viewNormal = TransformWorldToViewNormal(TransformObjectToWorldNormal(v.normalOS.xyz));
            float3 clipNormal = TransformWViewToHClip(viewNormal);
            float2 projectedNormal = normalize(clipNormal.xy);
            projectedNormal *= min(o.positionHCS.w, 1);
            projectedNormal.x *= aspect;
            o.positionHCS.xy += v.color.x * _OutlineWidth * projectedNormal.xy * 0.01;
        #else
            o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
        #endif
    #else
        o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
    #endif
    
    return o;
}

half4 frag (v2f i) : SV_Target
{
    #ifdef _USE_OUTLINE
        return _OutlineColor;
    #else
        return half4(0,0,0,0);
    #endif
}

#endif
