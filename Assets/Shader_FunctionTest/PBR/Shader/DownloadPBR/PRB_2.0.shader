Shader "Art_URP/FunctionTest/PBR_2.0"
{
    Properties
    {
		_Color("基础颜色", Color) = (1,1,1,1)
        [MainTexture]_MainTex ("主贴图", 2D) = "white" {}
        _Spc("基础 Metalness(R) Smoothness(A)", 2D) = "black" {}
        _Metallic("金属度",Range(0,1))=1
        _Roughness ("粗糙度", Range(0, 1)) = 1

		[Normal]_NormalTex("法线贴图", 2D) = "bump" {}
        _NormalScale("法线强度", Float) = 1.0

        _AO("基础 AO", 2D)= "white" {}
        
        _layer1Tex ("Layer1 Albedo (RGB) Smoothness (A)", 2D) = "white" {}
        _layer1Metal ("Layer1 Metalness", Range(0,1)) = 0
        _layer1Norm("Layer 1 Normal", 2D) = "bump" {}
        _layer1Breakup ("Layer1 Breakup (R)", 2D) = "white" {}
        _layer1BreakupAmnt ("Layer1 Breakup Amount", Range(0,1)) = 0.5
        _layer1Tiling("Layer1 Tiling", float) = 10
        _Power ("Layer1 Blend Amount", float ) = 1
        _Shift("Layer1 Blend Height", float) = 1 
        [Normal]_DetailNormal ("Detail Normal", 2D) = "bump" {} 
        _DetailInt ("DetailNormal Intensity", Range(0,1)) = 0.4
        _DetailTiling("DetailNormal Tiling", float) = 2 
        [Toggle(_KALOS_G_FACTOR_ON)] _Kalos_G_Factor ("Optimize with Kalos G Factor", Int) = 1
        _ShadowMainColor("ShadowMainColor", color) = (0,0,0,1)
        [Toggle(_AdditionalLights)] _AddLights ("AddLights", Float) = 1
 
    }
        SubShader
        {
           Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline"}
            LOD 100 
 
		 Pass
        {
		Tags { "LightMode" = "UniversalForward" }
 
            HLSLPROGRAM
 
			#pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
 
            
            #pragma multi_compile_fragment _ _SHADOWS_SOFT  // URP 软阴影
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN  // URP 主光阴影、联机阴影、屏幕空间阴影
 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "PBRMath.hlsl"                 //奇技淫巧全在里面
            #pragma multi_compile _ LIGHTMAP_ON     //光照贴图
 
 
			CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _ShadowMainColor; 
                float  _NormalScale;
                float  _Power;
                float  _DetailInt ;
                float  _DetailTiling ;
                float  _layer1Tiling ;
                float  _layer1Metal;
                float  _layer1BreakupAmnt;
                float  _Shift;
                float  _Metallic;;
                float  _Roughness;
                float4 _MainTex_ST;
                float4 _NormalTex_ST;
                float4 _Spc_ST;
                float4 _AO_ST;
                float4 _DetailBump_ST;
                float4 _layer1Tex_ST;
                float4 _layer1Norm_ST;
                float4 _layer1Breakup_ST;
            CBUFFER_END
			
            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);               
            TEXTURE2D(_Spc);            SAMPLER(sampler_Spc);
            TEXTURE2D(_AO);             SAMPLER(sampler_AO);
            TEXTURE2D(_NormalTex);      SAMPLER(sampler_NormalTex);
            TEXTURE2D(_DetailNormal);   SAMPLER(sampler_DetailNormal);        
            TEXTURE2D(_layer1Tex);      SAMPLER(sampler_layer1Tex);
            TEXTURE2D(_layer1Norm);     SAMPLER(sampler_layer1Norm);                
            TEXTURE2D(_layer1Breakup);  SAMPLER(sampler_layer1Breakup);
 
 
            struct VertexInput          
            {
                float4 positionOS : POSITION; 
                float2 uv : TEXCOORD0;
				float4 normalOS  : NORMAL;
				float4 tangentOS  : TANGENT;
                float2 uvLM : TEXCOORD1;
            };
 
            struct VertexOutput 
            {
                float4 position         : SV_POSITION; 
                float4 uv               : TEXCOORD0;            //xy是_MainTex的uv，zw是_NormlTex的UV
				float3 positionWS       : TEXCOORD1;
				float3 normalWS         : TEXCOORD2;
				float3 tangentWS        : TEXCOORD3;
				float3 bitangentWS      : TEXCOORD4;
                float2 uvLM             : TEXCOORD5;
                float3 vertexSH         : TEXCOORD6;
                half   fogCoord         : TEXCOORD7;            //单个fog可以写half
                float3 worldPos         : TEXCOORD8;
                //float4 shadowCoord : TEXCOORD8;
            };
 
            VertexOutput vert(VertexInput v)
            {
                VertexOutput o;

				VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.position = positionInputs.positionCS;
				o.positionWS = positionInputs.positionWS;
                //o.shadowCoord = GetShadowCoord(positionInputs);
                //o.shadowCoord = TransformWorldToShadowCoord(o.positionWS);

				VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS.xyz,v.tangentOS);
				o.normalWS = normalInputs.normalWS;
				o.tangentWS = normalInputs.tangentWS;
				o.bitangentWS = normalInputs.bitangentWS;

                o.worldPos = TransformObjectToWorld(v.positionOS.xyz);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv, _NormalTex);

                o.fogCoord = ComputeFogFactor(o.position.z);

                OUTPUT_LIGHTMAP_UV(v.uvLM, unity_LightmapST, o.uvLM);
                return o;
            }
 
            float4 frag(VertexOutput i): SV_Target 
            {
                //阴影
    			float4 SHADOW_COORDS = TransformWorldToShadowCoord(i.worldPos.xyz);
    			Light  lightDirectional     = GetMainLight(SHADOW_COORDS);
    			half   shadow        = lightDirectional.shadowAttenuation;

                //贴图采样
                float4 MainTex      = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
                half4 spec          = SAMPLE_TEXTURE2D(_Spc,sampler_Spc,i.uv.xy);
                half4 ao            = SAMPLE_TEXTURE2D(_AO,sampler_AO,i.uv.xy);

                half4 layer1        = SAMPLE_TEXTURE2D(_layer1Tex,sampler_layer1Tex,i.uv.xy* _layer1Tiling);
                half3 layer1norm    = UnpackNormal(SAMPLE_TEXTURE2D(_layer1Norm,sampler_layer1Norm,i.uv.xy* _layer1Tiling));
                half  layer1Breakup = SAMPLE_TEXTURE2D (_layer1Breakup,sampler_layer1Breakup, i.uv.xy* _layer1Tiling).r;
                half3 detnorm       = UnpackNormal(SAMPLE_TEXTURE2D (_DetailNormal,sampler_DetailNormal,i.uv.xy * _DetailTiling));
                
                //主法线处理
    			float4 normalTXS = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv.zw);
    			float3 normalTS  = UnpackNormalScale(normalTXS,_NormalScale);
                    //-------法线混合//
                    half3 modNormal     = normalTS + half3(layer1norm.r * 0.6, layer1norm.g * 0.6, 0);
                    //-------TBN矩阵换算等参数准备//
                    real3x3 TBN      = real3x3(i.tangentWS, i.bitangentWS, i.normalWS);
                    half3  normalWS  = TransformTangentToWorld(modNormal,TBN);
                    detnorm          = normalize(mul(detnorm,TBN));
                    normalTS         = normalize(mul(normalTS,TBN));
                    layer1norm       = normalize(mul(layer1norm,TBN));
                    //准备混合遮罩///万能的遮罩，后面给反射这些也要混合使用它！！！
                    half3 layer1direction = half3(0,1,0);
                    half blend            = dot(normalWS, layer1direction);
                    half blend2           = (blend * _Power + _Shift) * lerp(1, layer1Breakup, _layer1BreakupAmnt);
                    blend2 = saturate(pow(blend2, 3));
                    //合并法线:合并法线操作之前必须在世界空间（即纹理解包+TBN之后才能使用） 
                    half3 blendedNormal = lerp(normalTS, layer1norm, blend2); 
                    blendedNormal = blendedNormal + (detnorm * half3(_DetailInt,_DetailInt,0)); //恭喜你获得了这个关键的法线!!!                                                 

                //向量准备
                half3 L = normalize(lightDirectional.direction);
                half3 V = SafeNormalize(_WorldSpaceCameraPos - i.positionWS);
                half3 H = normalize(L + V); 
                half3 N = blendedNormal.rgb; 
                
                //向量点积
                half HdotL = max(dot(H, L), 1e-5); //1e-5代表10的负5次方，也就是0.00001 
                //half NdotL = max(dot(N, L), 1e-5); 
                half NdotL = dot(N, L)*0.5+0.5; 
                     NdotL = lerp(NdotL,max(dot(N, L), 1e-5),0.75);  //这个是我个人喜好！
                half NdotV = max(dot(N, V), 1e-5); 
                half HdotN = max(dot(H, N), 1e-5);
                
                //合并反射、AO等贴图（使用上面同样的那个Mask)
                half3 blendedAlbedo      = lerp(MainTex.rgb, layer1.rgb, blend2);
                half  blendedSmoothness  = lerp(spec.a, layer1.a, blend2);
                half3 blendedMetallic    = lerp(spec.r, _layer1Metal, blend2);
                
                //PBR参数准备
                half  metallic   = blendedMetallic.r * _Metallic;
                half  smoothness = blendedSmoothness;
                half  roughness  = (1 - smoothness) * _Roughness;
                half3 F0         = Direct_F0_Function(blendedAlbedo, metallic);             //这里面定义的方法使用了奇技淫巧，去包含文件去看
                half3 Direct_F   = Direct_F_Function(HdotL, F0);
                
                //----// 直线光漫反射
                half3 KS = Direct_F;
                half3 KD = (1 - KS) * (1 - metallic);
                half3 DirectDiffColor = KD * blendedAlbedo * lightDirectional.color * NdotL;
                
                // 镜面反射
                half Direct_D = Direct_D_Function(HdotN, roughness);
                
                //----// BRDF
                #if defined(_KALOS_G_FACTOR_ON)
                    half Direct_G = Direct_G_Function_Kalos(HdotL, roughness);
                #else
                    half Direct_G = Direct_G_Function(NdotL, NdotV, roughness);
                #endif
                
                #if defined(_KALOS_G_FACTOR_ON)
                    half3 BRDFSpecSection = (Direct_D * Direct_G) * Direct_F / (4 * HdotL);
                #else
                    half3 BRDFSpecSection = (Direct_D * Direct_G) * Direct_F / (4 * NdotL * NdotV);
                #endif

                half3 DirectSpeColor = BRDFSpecSection * lightDirectional.color * (NdotL * PI * ao.rgb);
                // 第一部分（直线光照结果）
                half3 DirectColor = DirectDiffColor + DirectSpeColor;

                // 第二部分：间接漫反射
                half3 shColor = SH_IndirectionDiff(N) * ao.r;
                half3 Indirect_KS = Indirect_F_Function(NdotV, F0, roughness);
                half3 Indirect_KD = (1 - Indirect_KS) * (1 - metallic);
                half3 IndirectDiffColor = shColor * Indirect_KD * blendedAlbedo;
                // return half4(IndirectDiffColor, 1); // jave.lin : 添加一个 反射探针 即可看到效果：reflection probe

                // 间接反射
                //----// 反射探针的间接光
                half3 IndirectSpeCubeColor = IndirectSpeCube(N, V, roughness, ao.r);
                half3 IndirectSpeCubeFactor = IndirectSpeFactor(roughness, smoothness, BRDFSpecSection, F0, NdotV);
                half3 IndirectSpeColor = IndirectSpeCubeColor * IndirectSpeCubeFactor;
                half3 IndirectColor = IndirectDiffColor + IndirectSpeColor;

                //half3 ambient = _GlossyEnvironmentColor.rgb;
                //1,2部分光照结果(总)
                half3 finalCol = DirectColor + IndirectColor;
                finalCol.rgb = MixFog(finalCol.rgb,i.fogCoord);

                //光照烘焙颜色
                half3  bakedGI = SAMPLE_GI(i.uvLM, i.vertexSH, normalWS);

                //float shadow = MainLightRealtimeShadow(i.shadowCoord);      // shadow
                
                finalCol.rgb = lerp(_ShadowMainColor.rgb * finalCol.rgb, finalCol.rgb, shadow);
                finalCol.rgb =finalCol.rgb+ bakedGI.rgb*finalCol.rgb;

    			clip(_Color.a-0.5);

                return  float4(finalCol.rgb,1) ;
            }
 
            ENDHLSL
        }
 
		UsePass "Universal Render Pipeline/Lit/ShadowCaster"
        UsePass "Universal Render Pipeline/Lit/DepthOnly"         //深度绘制Pass防止消失
    }
    FallBack "Packages/com.unity.render-pipelines.universal/FallbackError"
}