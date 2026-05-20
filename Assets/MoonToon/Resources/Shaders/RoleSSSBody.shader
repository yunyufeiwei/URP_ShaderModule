Shader "Unlit/QJNN/SimpleSSSLight_URP"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Tint("Tint",Color)=(1,1,1,1)
        _FrontSurfaceDistortion("FrontSurfaceDistortion",Range(0,2)) = 1
        _BackSurfaceDistortion("BackSurfaceDistortion",Range(0,2)) = 1
        _BackIntensity("BackIntensity",Range(0,1)) = 0
        _InteriorColor("InteriorColor",Color) = (1,1,1,1)
        _InteriorColorPower("InteriorColorPower",Range(0,1)) = 1
        _FrontSSSIntensity("FrontSSSIntensity",Range(0,1)) = 1
        _Gloss("Gloss",Range(0,1))=1
        _GlossColor("GlossColor",Color) = (1,1,1,1)
        _RimPower("RimPower",Range(0.1,5))=1
        _RimIntensity("RimIntensity",Range(0,2))=1

        [Header(Normal)]
        _NormalTex ("NormalTexture", 2D) = "bump" {}
        _NormalPower("NormalPower",Range(0,2))=1

        [Header(Mask)]
        _MaskTexture("MaskTexture",2D) = "white"{}
        _AoIntensity("AoIntensity",Range(0,1))= 0
        _AoColor("AoColor" ,Color) = (1,1,1,1)
        _MaskVarRPower("R",Range(0,1)) = 0
        _Ramp("Ramp",2D) = "white"{}
        _RampColor("RampColor",Color) = (1,1,1,1)
        _demo("demo",Vector) = (1,1,1,1)
        _LightPower("PointLightIntensity",Float) = 1
        _LightMaskTex("LightMaskTex",2D)= "black"{}
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "Queue"="Geometry"
            "RenderPipeline"="UniversalPipeline"
        }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            ZWrite On
            Cull Back
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            // URP 多光源开启（关键）
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fog

            // URP 核心库
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
            };

            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 positionHCS  : SV_POSITION;
                float3 positionWS   : TEXCOORD1;
                float3 normalWS     : TEXCOORD2;
                float3 tangentWS    : TEXCOORD3;
                float3 bitangentWS  : TEXCOORD4;
                float3 viewDirWS    : TEXCOORD5;
            };

            // URP 标准纹理定义
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalTex); SAMPLER(sampler_NormalTex);
            TEXTURE2D(_MaskTexture); SAMPLER(sampler_MaskTexture);
            TEXTURE2D(_Ramp); SAMPLER(sampler_Ramp);
            TEXTURE2D(_LightMaskTex); SAMPLER(sampler_LightMaskTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _NormalTex_ST;
                float4 _MaskTexture_ST;
                float4 _Ramp_ST;
                float4 _LightMaskTex_ST;

                float4 _Tint;
                float _FrontSurfaceDistortion;
                float _BackSurfaceDistortion;
                float _BackIntensity;
                float4 _InteriorColor;
                float _InteriorColorPower;
                float _FrontSSSIntensity;
                float _Gloss;
                float4 _GlossColor;
                float _RimPower;
                float _RimIntensity;
                float _NormalPower;
                float _AoIntensity;
                float4 _AoColor;
                float _MaskVarRPower;
                float4 _RampColor;
                float4 _demo;
                float _LightPower;
            CBUFFER_END

            half SubSurfaceScattering(half3 viewDir, half3 lightDir, half3 normalDir,
                half frontDistortion, half backDistortion, half frontIntensity)
            {
                half3 frontLitDir = normalDir * frontDistortion - lightDir;
                half3 backLitDir = normalDir * backDistortion + lightDir;
                half frontSSS = saturate(dot(viewDir, -frontLitDir));
                half backSSS = saturate(dot(viewDir, -backLitDir));
                return saturate(frontSSS * frontIntensity + backSSS);
            }

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionHCS = TransformWorldToHClip(output.positionWS);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.viewDirWS = GetWorldSpaceViewDir(output.positionWS);

                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.tangentWS = TransformObjectToWorldDir(input.tangentOS.xyz);
                output.bitangentWS = cross(output.normalWS, output.tangentWS) * input.tangentOS.w;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                
                float2 uv = input.uv;
                float3 positionWS = input.positionWS;
                float3 viewDirWS = normalize(input.viewDirWS);

                // 采样纹理
                float4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                float4 maskVar = SAMPLE_TEXTURE2D(_MaskTexture, sampler_MaskTexture, uv);
                float4 lightMask = SAMPLE_TEXTURE2D(_LightMaskTex, sampler_LightMaskTex, uv);

                // 法线
                float3 normalWS = normalize(input.normalWS);
                float3 tangentWS = normalize(input.tangentWS) * _NormalPower;
                float3 bitangentWS = normalize(input.bitangentWS) * _NormalPower;
                float3x3 TBN = float3x3(tangentWS, bitangentWS, normalWS);
                float3 nTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, TRANSFORM_TEX(uv,_NormalTex)));
                float3 N = normalize(mul(nTS, TBN));

                // 最终颜色
                float3 finalColor = 0.0h;

                // ==============================================
                // 1. 主光源计算（方向光）
                // ==============================================
                Light mainLight = GetMainLight();
                float3 L = normalize(mainLight.direction);
                half atten = mainLight.shadowAttenuation * mainLight.distanceAttenuation;

                half sss = SubSurfaceScattering(viewDirWS, L, N, _FrontSurfaceDistortion, _BackSurfaceDistortion, _FrontSSSIntensity);
                half3 sssCol = lerp(_InteriorColor.rgb, mainLight.color, saturate(pow(sss, _InteriorColorPower))) * sss * maskVar.g;

                half nl = saturate(dot(N, L));
                half blbt = nl * 0.5 + 0.5;
                float2 rampUV = float2(blbt - _demo.x, blbt - _demo.y);
                float3 rampVar = SAMPLE_TEXTURE2D(_Ramp, sampler_Ramp, rampUV).rgb;
                float3 unlitCol = mainTex.rgb * _RampColor.rgb * 0.5;
                float3 diffuseCol = lerp(unlitCol, mainTex.rgb * _Tint.rgb, saturate(rampVar.r));

                float specPow = exp2((1 - _Gloss) * 10 + 1);
                float3 H = normalize(L + viewDirWS);
                float spec = pow(max(0, dot(H, N)), specPow);
                float3 specCol = spec * mainLight.color * (maskVar.r + _MaskVarRPower) * _GlossColor.rgb;

                half rim = 1.0 - saturate(dot(N, viewDirWS));
                half rimValue = lerp(rim, 0, sss);
                float3 rimCol = lerp(_InteriorColor.rgb, mainLight.color, rimValue) * pow(rimValue, _RimPower) * _RimIntensity;

                float ao = lerp(_AoColor.rgb, 1.0, saturate(maskVar.b + _AoIntensity));
                float3 mainColor = (diffuseCol + sssCol + specCol + rimCol * rampVar.r) * ao * atten;
                finalColor += mainColor * (1.0 - lightMask.g);

                // ==============================================
                // 2. 额外多光源（点光/聚光灯）URP 标准写法
                // ==============================================
                int addLightCount = GetAdditionalLightsCount();
                for (int i = 0; i < addLightCount; i++)
                {
                    Light light = GetAdditionalLight(i, positionWS);
                    float3 L_add = normalize(light.direction);
                    half nl_add = saturate(dot(N, L_add));
                    half atten_add = light.distanceAttenuation * light.shadowAttenuation * _LightPower;
                    
                    float3 addColor = mainTex.rgb * nl_add * light.color * atten_add;
                    finalColor += addColor * (1.0 - lightMask.g);
                }

                return half4(finalColor, 1.0h);
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}