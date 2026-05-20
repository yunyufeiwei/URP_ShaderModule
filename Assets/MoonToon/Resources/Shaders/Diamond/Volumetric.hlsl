#ifndef __FUNKTRONIC_LABS_VOLUMETRIC_CGINC__
#define __FUNKTRONIC_LABS_VOLUMETRIC_CGINC__

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

//////////////////////////////////////////////////
// GLOBAL FUNCTIONS
//////////////////////////////////////////////////
float lumin(float3 rgb)
{
    return dot(rgb, float3(0.299, 0.587, 0.114));
}

//////////////////////////////////////////////////
// URP 标准纹理定义
//////////////////////////////////////////////////
TEXTURE2D(_Layer0Tex);
SAMPLER(sampler_Layer0Tex);
TEXTURE2D(_Layer1Tex);
SAMPLER(sampler_Layer1Tex);
TEXTURE2D(_Layer2Tex);
SAMPLER(sampler_Layer2Tex);
TEXTURE2D(_MarbleTex);
SAMPLER(sampler_MarbleTex);
TEXTURE2D(_CausticMap);
SAMPLER(sampler_CausticMap);
TEXTURE2D(_SurfaceAlphaMaskTex);
SAMPLER(sampler_SurfaceAlphaMaskTex);

//////////////////////////////////////////////////
// MATERIAL PROPERTIES
//////////////////////////////////////////////////
CBUFFER_START(UnityPerMaterial)
float4 _Layer0Tex_ST;
float4 _Layer0Tint;
float _Layer0SpeedX;
float _Layer0SpeedY;

float4 _Layer1Tex_ST;
float4 _Layer1Tint;
float _Layer1SpeedX;
float _Layer1SpeedY;

float4 _Layer2Tex_ST;
float4 _Layer2Tint;
float _Layer2SpeedX;
float _Layer2SpeedY;

float _LayerHeightBias;
float _LayerHeightBiasStep;
float _LayerDepthFalloff;

float4 _MarbleTex_ST;
float _MarbleHeightScale;
float _MarbleHeightCausticOffset;

float4 _CausticMap_ST;
float4 _CausticTint;
float _CausticScrollSpeed;

float4 _SurfaceAlphaMaskTex_ST;
float4 _SurfaceAlphaColor;

float _FresnelTightness;
float4 _FresnelColorInside;
float4 _FresnelColorOutside;

float _InnerLightTightness;
float4 _InnerLightColorInside;
float4 _InnerLightColorOutside;

float _SpecularTightness;
float _SpecularBrightness;
CBUFFER_END

//////////////////////////////////////////////////
// APP DATA
//////////////////////////////////////////////////
struct appdata
{
    float4 positionOS   : POSITION;
    float3 normalOS      : NORMAL;
    float3 tangentOS     : TANGENT;
    float2 uv            : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

//////////////////////////////////////////////////
// V2F
//////////////////////////////////////////////////
struct v2f
{
    float4 positionHCS   : SV_POSITION;
    float2 uv            : TEXCOORD0;
    float3 positionWS    : TEXCOORD1;
    float3 normalWS      : TEXCOORD2;
    float3 viewDirWS     : TEXCOORD3;
    float3 reflectWS     : TEXCOORD4;
    float3 camLocalVec   : TEXCOORD5;
    float4 screenPos     : TEXCOORD6;

    #if defined(EnableFog)
    UNITY_FOG_COORDS(7)
    #endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

//////////////////////////////////////////////////
// VERTEX SHADER
//////////////////////////////////////////////////
v2f vertVolumetric(appdata v)
{
    v2f o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
    float3 normalWS = TransformObjectToWorldNormal(v.normalOS);
    float3 viewDirWS = GetWorldSpaceViewDir(positionWS);
    float3 reflectWS = reflect(-viewDirWS, normalWS);

    float3 binormal = cross(v.tangentOS.xyz, v.normalOS.xyz);
    float3x3 TBN = float3x3(v.tangentOS.xyz, binormal, v.normalOS.xyz);
    float3 camOS = TransformWorldToObject(_WorldSpaceCameraPos);
    float3 toCamOS = camOS - v.positionOS.xyz;
    float3 camLocalVec = mul(TBN, toCamOS);

    o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
    o.uv = v.uv;
    o.positionWS = positionWS;
    o.normalWS = normalWS;
    o.viewDirWS = viewDirWS;
    o.reflectWS = reflectWS;
    o.camLocalVec = camLocalVec;
    o.screenPos = ComputeScreenPos(o.positionHCS);

    #if defined(EnableFog)
    UNITY_TRANSFER_FOG(o, o.positionHCS);
    #endif

    return o;
}

//////////////////////////////////////////////////
// FRAGMENT SHADER
//////////////////////////////////////////////////
half4 fragVolumetric(v2f i) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);

    float3 N = normalize(i.normalWS);
    float3 V = normalize(i.viewDirWS);
    float phong = saturate(dot(N, V));

    float2 uv = i.uv;
    float2 uvMarble = uv;

    // Caustic
    float caustic = 0.0;
    #ifdef EnableCaustic
    float2 causticUV = TRANSFORM_TEX(uv, _CausticMap) + float2(0, _Time.x * _CausticScrollSpeed);
    caustic = SAMPLE_TEXTURE2D(_CausticMap, sampler_CausticMap, causticUV).r;
    uvMarble += float2(caustic, _Time.x) * _MarbleHeightCausticOffset;
    #endif

    // Parallax
    float3 eyeVec = normalize(i.camLocalVec);
    float height = SAMPLE_TEXTURE2D(_MarbleTex, sampler_MarbleTex, TRANSFORM_TEX(uvMarble, _MarbleTex)).r;
    float vOffset = height * _MarbleHeightScale - (_MarbleHeightScale * 0.5);
    float2 newUV = uv + eyeVec.xy * vOffset;

    float3 color = 0.0;
    float alpha = 0.0;
    float depthFade = 1.0;
    float heightBias = _LayerHeightBias;

    // Layer 0
    {
        float2 baseUV = TRANSFORM_TEX(uv, _Layer0Tex) + _Time.x * float2(_Layer0SpeedX, _Layer0SpeedY);
        float2 finalUV = baseUV + eyeVec.xy * vOffset - eyeVec.xy * heightBias;
        color += SAMPLE_TEXTURE2D(_Layer0Tex, sampler_Layer0Tex, finalUV).rgb * depthFade * _Layer0Tint.rgb;
        depthFade *= _LayerDepthFalloff;
        heightBias += _LayerHeightBiasStep;
    }

    // Layer 1
    #ifdef EnableLayer1
    {
        float2 baseUV = TRANSFORM_TEX(uv, _Layer1Tex) + _Time.x * float2(_Layer1SpeedX, _Layer1SpeedY);
        float2 finalUV = baseUV + eyeVec.xy * vOffset - eyeVec.xy * heightBias;
        color += SAMPLE_TEXTURE2D(_Layer1Tex, sampler_Layer1Tex, finalUV).rgb * depthFade * _Layer1Tint.rgb;
        depthFade *= _LayerDepthFalloff;
        heightBias += _LayerHeightBiasStep;
    }
    #endif

    // Layer 2
    #ifdef EnableLayer2
    {
        float2 baseUV = TRANSFORM_TEX(uv, _Layer2Tex) + _Time.x * float2(_Layer2SpeedX, _Layer2SpeedY);
        float2 finalUV = baseUV + eyeVec.xy * vOffset - eyeVec.xy * heightBias;
        color += SAMPLE_TEXTURE2D(_Layer2Tex, sampler_Layer2Tex, finalUV).rgb * depthFade * _Layer2Tint.rgb;
    }
    #endif

    // Marble
    color += SAMPLE_TEXTURE2D(_MarbleTex, sampler_MarbleTex, TRANSFORM_TEX(newUV, _MarbleTex)).rgb;
    alpha += saturate(lumin(color));

    // Fresnel
    #ifdef EnableFresnel
    float fresnel = pow(1.0 - phong, _FresnelTightness);
    float3 fresnelColor = lerp(_FresnelColorInside.rgb, _FresnelColorOutside.rgb, fresnel) * fresnel;

    #ifdef EnableFresnelUseSkybox
    float3 sky = SampleSkyboxReflect(i.reflectWS);
    color += fresnelColor * sky;
    #else
    color += fresnelColor;
    #endif
    alpha += fresnel;
    #endif

    // Inner Light
    #ifdef EnableInnerLight
    float inner = pow(phong, _InnerLightTightness);
    float3 innerColor = lerp(_InnerLightColorOutside.rgb, _InnerLightColorInside.rgb, inner) * inner;
    color += innerColor;
    alpha += inner;
    #endif

    // Caustic
    #ifdef EnableCaustic
    color += _CausticTint.rgb * caustic;
    alpha += caustic * _CausticTint.a;
    #endif

    // Surface Mask
    #ifdef EnableSurfaceMask
    float mask = SAMPLE_TEXTURE2D(_SurfaceAlphaMaskTex, sampler_SurfaceAlphaMaskTex, TRANSFORM_TEX(uv, _SurfaceAlphaMaskTex)).r;
    color += _SurfaceAlphaColor.rgb * mask;
    alpha += mask;
    #endif

    // Specular
    #ifdef EnableSpecular
    Light light = GetMainLight();
    float3 L = normalize(light.direction);
    float3 R = reflect(-L, N);
    float spec = pow(saturate(dot(R, V)), _SpecularTightness);
    color += light.color * spec * _SpecularBrightness;
    alpha += spec * _SpecularBrightness;
    #endif

    color = saturate(color);
    alpha = saturate(alpha);

    #if defined(EnableFog)
    UNITY_APPLY_FOG(i.fogCoord, color);
    #endif

    return half4(color, alpha);
}

#endif