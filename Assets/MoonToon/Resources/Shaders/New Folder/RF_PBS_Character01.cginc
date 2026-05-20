#ifndef _RF_PBS_CHARACTOR_CGINC_
#define _RF_PBS_CHARACTOR_CGINC_

#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "RF_BRDF.cginc"
#include "UnityStandardConfig.cginc"
#include "HLSLSupport.cginc"

#ifdef POINT
#define LIGHTING_ONLY_COORDS(idx1)  unityShadowCoord3 _LightCoord : TEXCOORD##idx1; 
#define TRANSFER_LIGHTING_ONLY(a)   a._LightCoord = mul(unity_WorldToLight, mul(unity_ObjectToWorld, v.vertex)).xyz;
#define LIGHT_ONLY_ATTENUATION(a)   (tex2D(_LightTexture0, dot(a._LightCoord,a._LightCoord).rr).UNITY_ATTEN_CHANNEL)
#endif

#ifdef SPOT
#define LIGHTING_ONLY_COORDS(idx1)  unityShadowCoord4 _LightCoord : TEXCOORD##idx1;
#define TRANSFER_LIGHTING_ONLY(a)   a._LightCoord = mul(unity_WorldToLight, mul(unity_ObjectToWorld, v.vertex));
#define LIGHT_ONLY_ATTENUATION(a)   ((a._LightCoord.z > 0) * UnitySpotCookie(a._LightCoord) * UnitySpotAttenuate(a._LightCoord.xyz))
#endif



#ifdef POINT_COOKIE
#define LIGHTING_ONLY_COORDS(idx1)  unityShadowCoord3 _LightCoord : TEXCOORD##idx1; 
#define TRANSFER_LIGHTING_ONLY(a)   a._LightCoord = mul(unity_WorldToLight, mul(unity_ObjectToWorld, v.vertex)).xyz; 
#define LIGHT_ONLY_ATTENUATION(a)   (tex2D(_LightTextureB0, dot(a._LightCoord,a._LightCoord).rr).UNITY_ATTEN_CHANNEL * texCUBE(_LightTexture0, a._LightCoord).w * SHADOW_ATTENUATION(a))
#endif



struct vIn
{
    float4 vertex   : POSITION;
    half3 normal    : NORMAL;
    half4 tangent   : TANGENT;
    float2 uv       : TEXCOORD0;
	UNITY_VERTEX_INPUT_INSTANCE_ID
		half4 color : COLOR;
};

struct v2f
{
    float4 pos      : SV_POSITION;
    float2 uv       : TEXCOORD0;
    half4 viewWorld : TEXCOORD1;
    float4 tSpace0  : TEXCOORD2;
    float4 tSpace1  : TEXCOORD3;
    float4 tSpace2  : TEXCOORD4;
    half4 vertexGI  : TEXCOORD5;
	half3 normal : TEXCOORD6;
	half3 binWorld : TEXCOORD7;
	half4 color : TEXCOORD8;
    UNITY_SHADOW_COORDS(9)
	UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};


inline half4 VertexGI(vIn v, float3 posWorld, half3 nomWorld)
{
	half4 vertexGI = 0;

	
#ifdef UNITY_SHOULD_SAMPLE_SH
#ifdef VERTEXLIGHT_ON
	vertexGI.rgb = Shade4PointLights(
		unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
		unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
		unity_4LightAtten0, posWorld, nomWorld);
#endif
	vertexGI.rgb += ShadeSH9(half4(nomWorld, 1.0));
#endif


	return vertexGI;
}

inline half3 DiffuseGI(half4 vertexGI)
{
    half3 diffuseGI = vertexGI.rgb;

    return diffuseGI;
}

inline half3 SpecularGIImpl(UNITY_ARGS_TEXCUBE(spceCube), half smoothness, half3 viewWorld, half3 nomWorld, half4 decodeInstructions)
{
    half roughness = 1 - smoothness;
    roughness = roughness * (1.7 - 0.7 * roughness);
    half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(spceCube, reflect(-viewWorld, nomWorld), roughness * 6);
    return DecodeHDR(rgbm, decodeInstructions);
}
inline half3 SpecularGIForUI(UNITY_ARGS_TEXCUBE(spceCube), half smoothness, half3 viewWorld, half3 nomWorld, half4 decodeInstructions)
{
	half roughness = 1 - smoothness;
	roughness = roughness * (1.7 - 0.7 * roughness);
	half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(spceCube, reflect(-viewWorld, nomWorld), roughness * 6);
	return DecodeHDR(rgbm, decodeInstructions);
}

inline half3 SpecularGI(half smoothness, half3 viewWorld, half3 nomWorld)
{
	half3 specular;
	half3 env0 = SpecularGIImpl(UNITY_PASS_TEXCUBE(unity_SpecCube0), smoothness, viewWorld, nomWorld, unity_SpecCube0_HDR);
	#ifdef UNITY_SPECCUBE_BLENDING
		const float kBlendFactor = 0.99999;
		float blendLerp = unity_SpecCube0_BoxMin.w;
		UNITY_BRANCH
			if (blendLerp < kBlendFactor)
			{
				half3 env1 = SpecularGIImpl(UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0), smoothness, viewWorld, nomWorld, unity_SpecCube1_HDR);
				specular = lerp(env1, env0, blendLerp);
			}
			else
			{
				specular = env0;
			}
	#else
		specular = env0;
	#endif
    return specular;
}

inline fixed3 GetSaturation (fixed3 col, float sat)
{
	fixed average = (col.r + col.g + col.b) / 3;
	col.rgb +=  (col.rgb - average) * sat;
	return col;
}

inline half4 PBS_Charactor01(half4 albedo ,half3 diffColor, half3 specColor, half3 diffColorIndirect, half3 specColorIndirect, half3 lightcolor, half smoothness,half oneMinusReflectivity, float3 normal, float3 viewdir, float3 lightdir,half Scal,half SpeArea,half SpeStr,half4 FaceColor, half3 FaceColor2, half3 atten,half4 vertColor,half FaceSide,half FaceStr,half4 FaceColor3, half saturation)

{
	float perceptualRoughness = 1.0 - smoothness;
	float3 halfDir = Unity_SafeNormalize(lightdir + viewdir);

	half ndv = saturate(dot(normal, viewdir));
    half nv = abs(dot(normal, viewdir));    
    half ndl = dot(normal, lightdir);
    half nl = saturate(ndl);
	float nh = saturate(dot(normal, halfDir));
    half lv = saturate(dot(lightdir, viewdir));
    half lh = saturate(dot(lightdir, halfDir));

 
	half nl2 =saturate (dot(normal, -lightdir));
	//return half4(nl2.rrr, 1);
	float roughness = perceptualRoughness * perceptualRoughness;
	float V = SmithJointGGXVisibility(nl, nv, roughness);
	float D = GGXMulPI(nh, roughness);

	float specular = V * D;

#ifdef UNITY_COLORSPACE_GAMMA
	specular = sqrt(max(1e-4h, specular));
#endif
	specular = max(0, specular * nl);

#ifdef UNITY_COLORSPACE_GAMMA
    half surfaceReduction = 1.0 - 0.28 * roughness * perceptualRoughness;
#else
    half surfaceReduction = 1.0 / (roughness * roughness + 1.0);
#endif

//布的各项异性 皮肤————————————————————
nh = pow(nh,5);
half ClothSpe =1-abs(nh*2-1);

ClothSpe = pow(ClothSpe,Scal)*SpeStr;
half SkinArea =saturate(vertColor.b-vertColor.g);  /*saturate((SpeArea-0.99)*100)*/;

half ClothArea =saturate(SpeArea );
// half3 ClothSpeFinal =ClothSpe * ClothArea*(nl*0.5+0.5);
half3 ClothSpeFinal =ClothSpe * ClothArea*albedo.rgb*(nl*0.5+0.5)*lightcolor;
ClothSpeFinal = GetSaturation(ClothSpeFinal, saturation);
// return half4(GetSaturation(ClothSpeFinal, saturation),1);



  float sl =saturate( smoothstep(2.99, 1, pow(nl,1)) - smoothstep(0, 1, pow(nl, 1)));

  float3 subsurfaceColor = sl * FaceColor.rgb*SkinArea*2;

  float3 subsurfaceColor2 = (1 - sl)*FaceColor2*SkinArea;


  half skinNl = pow(ndl*0.5 + 0.5, 2.2) * 1.4  + nl2* FaceColor.a;
  half subNl = pow((ndl*0.5 + 0.5)*0.5 + 0.5, 4) * 2;
   
  half nvpow =saturate( pow((1- ndv), FaceSide));
  nvpow = saturate(nvpow * FaceStr);
  half3 faceColor3 = FaceColor3 * nvpow + (1 - nvpow);

//—————————————————————————— lightcolor * diffuse

  diffColorIndirect = diffColorIndirect * atten*(1 - skinNl) + diffColorIndirect * skinNl*(atten*0.5 + 0.5);
 half3 color = diffColor * (diffColorIndirect + lightcolor * (nl * saturate((vertColor.g - SkinArea ))*atten + (nl*0.7+0.3)*(1-vertColor.b)  + (skinNl * SkinArea)*(atten* vertColor.r*atten + (1 - vertColor.r))*(atten*0.5+0.5) + (subsurfaceColor+ subsurfaceColor2)* subNl))  +
	 specular * lightcolor * Fresnel(specColor, lh) +
	 surfaceReduction * (specColorIndirect * (1 - SkinArea)) * FresnelLerp(specColor, saturate(smoothness + (1 - oneMinusReflectivity)), nv) * (1 - SkinArea);
    color += ClothSpeFinal*atten;
	color *= faceColor3;
    return half4(color,1);

}

inline half4 PBS_Boss( half3 diffColor, half3 specColor, half3 diffColorIndirect, half3 specColorIndirect, half3 lightcolor, half smoothness, half oneMinusReflectivity, float3 normal, float3 viewdir, float3 lightdir)

{
	half perceptualRoughness = 1.0 - smoothness;
	float3 halfDir = Unity_SafeNormalize(lightdir + viewdir);

	half nv = abs(dot(normal, viewdir));
	half ndl = dot(normal, lightdir);
	half nl = saturate(ndl);
	float nh = saturate(dot(normal, halfDir));
	half lv = saturate(dot(lightdir, viewdir));
	half lh = saturate(dot(lightdir, halfDir));


	half nl2 = saturate(dot(normal, -lightdir));
	//return half4(nl2.rrr, 1);
	float roughness = perceptualRoughness * perceptualRoughness;
	float V = SmithJointGGXVisibility(nl, nv, roughness);
	float D = GGXMulPI(nh, roughness);

	float specular = V * D;

#ifdef UNITY_COLORSPACE_GAMMA
	specular = sqrt(max(1e-4h, specular));
#endif
	specular = max(0, specular * nl);

#ifdef UNITY_COLORSPACE_GAMMA
	half surfaceReduction = 1.0 - 0.28 * roughness * perceptualRoughness;
#else
	half surfaceReduction = 1.0 / (roughness * roughness + 1.0);
#endif


	//—————————————————————————— lightcolor * diffuse


	half3 color = diffColor * (diffColorIndirect + lightcolor * nl) +
		specular * lightcolor * Fresnel(specColor, lh) +
		surfaceReduction * specColorIndirect * FresnelLerp(specColor, saturate(smoothness + (1 - oneMinusReflectivity)), nv) ;

	return half4(color, 1);

}



#endif 