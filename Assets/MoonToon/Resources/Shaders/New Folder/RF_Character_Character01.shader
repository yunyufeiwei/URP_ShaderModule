Shader "RF/Character/Character01_URP"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 1
        _MainTex("Albedo", 2D) = "white" {}
        _Color("Color", Color) = (1,1,1,1)
        _Cutoff("Alpha Cutoff", Range(0.0, 1.01)) = 0.5
        [NoScaleOffset]_NormTex("Normal(RG),Emission(B)", 2D) = "white" {}
        [NoScaleOffset]_MaskTex("Mask (metallic(R), smoothness(G),colour(B),colour(G)))", 2D) = "white" {}
        [NoScaleOffset]_EnvCube("Env CubeMap", Cube) = "white" {}
        [HideInInspector]_CharacterAlpha("NpcAlpha",range(0,1)) = 1
        _FaceTex("FaceTex(RGB),Emission(R),Flow(G)",2D) = "gray"{}
        _FaceColor("FaceColor",color) = (1,1,1,0.2)
        _FaceColor2("FaceColor",color) = (1,1,1,0.2)
        _FaceSide("FaceSide",range(0.5,20)) =0.6
        _FaceStr("FaceStr",range(0,1)) = 0.6
        _FaceColor3("FaceColor3",color)=(1,1,1,1)
        _ShadowSelfColor("ShadowSelfColor",range(0,1)) = 1

        _EmissionColor("EmissionColor",Color) = (1,1,1,0.2)
        _EmissionSpeed("EmissionSpeed",float) = 0

        _SpeScal ("ClothSpeScal",Range(1,10)) = 1
        _SpeStr ("ClothSpeStr",Range(0,10)) = 1
        _Saturation("Saturation",Range(-1,5)) = 0

        _TimeLightWidth("TimeLightScal",Range(0.01,0.99)) = 0.8
        _TimeLightColor("TimeLightColor",color) = (0,0,0,0)
        _TimeLightStr("TimeLightStr",float) = 1
        _TimeLightSpeed("TimeLightSpeed",float) = 0.1

        [Gamma]_Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5

        [HideInInspector] _Mode("", Float) = 0.0
        [HideInInspector] _SrcBlend("", Float) = 1.0
        [HideInInspector] _DstBlend("", Float) = 0.0
        [HideInInspector] _ZWrite("", Float) = 1.0

        [MaterialToggle] _GrayValue("GrayValue", Float) = 0
        _CastColor1("CastColor1", Color) = (1,1,1,1)
        _CastLight1("ColorLight1", Range(0, 10)) = 1
        _ClothSpeStr1("ClothSpeStr",range(-5,10)) = 0

        _CastColor2("CastColor2", Color) = (1,1,1,1)
        _CastLight2("ColorLight2", Range(0, 10)) = 1
        _ClothSpeStr2("ClothSpeStr",range(-5,10)) = 0

        _CastColor3("CastColor3", Color) = (1,1,1,1)
        _CastLight3("ColorLight3", Range(0, 10)) = 1
        _ClothSpeStr3("ClothSpeStr",range(-5,10)) = 0

        _MainTexHair("HairTex",2D) = "White"{}
        _HairColor1st("HairColor1st",Color) = (1,1,1,1)
        _HairColor2ed("HairColor2ed",Color) = (1,1,1,1)
        _HairSpecular1st("HairSpecular1st",Color) = (1,1,1,0.2)
        _HairSpecular2ed("HairSpecular2ed",Color) = (1,1,1,0.2)
        _HairSpeScal("HairSpeScalOne", Range(0, 256)) = 1
        _HairPrimaryShift("PrimaryShift",float) = 0
        _HairAO1st("HairAO1st",color) = (1,1,1,1)
        _HairAO2ed("HairAO2ed",color) = (1,1,1,1)

        [Toggle] _Niuqu("NiuQuKey",float) = 0
        [HDR]_ChaTintColor("TintColor",color) = (1,1,1,1)
        _NiuQuTex("NiuQu(RGBA)", 2D) = "black" {}
        _Animation1stX("SpeedX",float) = 0.5
        _Animation1stY("SpeedY",float) = 0.5
        _UvSpeed2edX("Speed",float) = 0
        _Force1stX("Power", range(-0.2,0.2)) = 0

        [Toggle] _Fresnel("FresnelKey",float) = 0
        _FalloffLevel("FalloffLevel", Range(0, 20)) = 2
        [HDR]_ColorF("Color",color) = (1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "Queue"="Transparent"
            "RenderPipeline"="UniversalPipeline"
        }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            Cull[_Cull]
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #pragma multi_compile _ _ALPHABLEND_ON
            #pragma multi_compile _ _ALPHATEST_ON
            #pragma multi_compile _ _NIUQU_ON
            #pragma multi_compile _ _FRESNEL_ON
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _Color;
            float _Cutoff;
            float _Metallic;
            float _Glossiness;
            float _SpeScal;
            float _SpeStr;
            float4 _FaceColor;
            float4 _FaceColor2;
            float _FaceSide;
            float _FaceStr;
            float4 _FaceColor3;
            float4 _EmissionColor;
            float _EmissionSpeed;
            float _TimeLightWidth;
            float4 _TimeLightColor;
            float _TimeLightStr;
            float _TimeLightSpeed;
            float _CharacterAlpha;
            float _ShadowSelfColor;
            float _Saturation;

            float _GrayValue;
            float4 _CastColor1;
            float4 _CastColor2;
            float4 _CastColor3;
            float _CastLight1;
            float _CastLight2;
            float _CastLight3;
            float _ClothSpeStr1;
            float _ClothSpeStr2;
            float _ClothSpeStr3;

            float4 _MainTexHair_ST;
            float4 _HairColor1st;
            float4 _HairColor2ed;
            float4 _HairSpecular1st;
            float4 _HairSpecular2ed;
            float _HairSpeScal;
            float _HairPrimaryShift;
            float4 _HairAO1st;
            float4 _HairAO2ed;

            float _Niuqu;
            float4 _ChaTintColor;
            float _Animation1stX;
            float _Animation1stY;
            float _UvSpeed2edX;
            float _Force1stX;

            float _Fresnel;
            float _FalloffLevel;
            float4 _ColorF;

            float4 _DLightShadowColorCha;
            float4 _CharacterReColor;
            float _RainInstensity;
            float4 _UIWorldSpaceCameraPos;
            float _EffectWeight;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormTex);
            SAMPLER(sampler_NormTex);
            TEXTURE2D(_MaskTex);
            SAMPLER(sampler_MaskTex);
            TEXTURE2D(_FaceTex);
            SAMPLER(sampler_FaceTex);
            TEXTURE2D(_MainTexHair);
            SAMPLER(sampler_MainTexHair);
            TEXTURE2D(_NiuQuTex);
            SAMPLER(sampler_NiuQuTex);
            TEXTURECUBE(_EnvCube);
            SAMPLER(sampler_EnvCube);

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 uv0          : TEXCOORD0;
                float4 color        : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 positionWS   : TEXCOORD1;
                float3 normalWS     : TEXCOORD2;
                float3 tangentWS    : TEXCOORD3;
                float3 binormalWS   : TEXCOORD4;
                float3 viewDirWS    : TEXCOORD5;
                float4 vertexGI     : TEXCOORD6;
                float4 color        : COLOR;
                //UNITY_FOG_COORDS(7)
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float3 ShiftTangent1(float3 T, float3 N, float shift)
            {
                return normalize(T + shift * N);
            }

            float StrandSpecular(float3 T, float3 V, float3 L, float exponent)
            {
                float3 H = normalize(L + V);
                float dotTH = dot(T, H);
                float sinTH = sqrt(1 - dotTH * dotTH);
                float dirAtten = smoothstep(-1, 0, dotTH);
                return dirAtten * pow(sinTH, exponent);
            }

            Varyings vert(Attributes v)
            {
                Varyings o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv0, _MainTex);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);
                o.binormalWS = cross(o.normalWS, o.tangentWS) * v.tangentOS.w;
                o.viewDirWS = GetWorldSpaceViewDir(o.positionWS);
                o.color = v.color;

                o.vertexGI = float4(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w, 1);
                //UNITY_TRANSFER_FOG(o, o.positionHCS);
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float2 uv = i.uv;
                float3 positionWS = i.positionWS;
                float3 viewDirWS = normalize(i.viewDirWS);
                float3 normalWS = normalize(i.normalWS);
                float3 tangentWS = normalize(i.tangentWS);
                float3 binormalWS = normalize(i.binormalWS);
                float3x3 TBN = float3x3(tangentWS, binormalWS, normalWS);

                Light mainLight = GetMainLight();
                float3 L = normalize(mainLight.direction);
                float3 lightColor = mainLight.color;

                if (uv.y < 1.5)
                {
                    float4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                    float4 normTex = SAMPLE_TEXTURE2D(_NormTex, sampler_NormTex, uv);
                    float4 maskTex = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, uv);
                    float4 faceTex = SAMPLE_TEXTURE2D(_FaceTex, sampler_FaceTex, uv);

                    float3 normalTS = UnpackNormal(normTex);
                    float3 N = normalize(mul(normalTS, TBN));

                    float albedoAlpha = mainTex.a * _Color.a;
                    float3 albedo = mainTex.rgb * _Color.rgb;

                    float skinArea = saturate(1 - i.color.g);
                    float eyeArea = saturate(1 - i.color.b);
                    float noSkinArea = 1 - skinArea - eyeArea;

                    float gray = Luminance(albedo);
                    float3 grayColor = lerp(albedo, gray.rrr, _GrayValue);

                    float3 castColor = albedo;
                    castColor = lerp(castColor, _CastColor1.rgb * _CastLight1 * albedo, skinArea);
                    castColor = lerp(castColor, _CastColor2.rgb * _CastLight2 * grayColor, saturate(maskTex.b * noSkinArea));
                    castColor = lerp(castColor, _CastColor3.rgb * _CastLight3 * grayColor, saturate(maskTex.a * noSkinArea));
                    albedo = castColor;

                    float NdotL = saturate(dot(N, L));
                    float diffuse = NdotL * 0.5 + 0.5;

                    float metallic = _Metallic * maskTex.r;
                    float smoothness = _Glossiness * (1 - maskTex.g);
                    float specPow = exp2(smoothness * 10 + 1);

                    float3 H = normalize(L + viewDirWS);
                    float NdotH = saturate(dot(N, H));
                    float spec = pow(NdotH, specPow) * _SpeStr;

                    float3 diffuseColor = albedo * (1 - metallic);
                    float3 specularColor = lerp(0.04, albedo, metallic);

                    float3 finalColor = diffuseColor * diffuse * lightColor + spec * specularColor * lightColor;

                    float3 emission = normTex.a * _EmissionColor.rgb * _EmissionColor.a * (1 - abs(sin(_Time.y * _EmissionSpeed)));
                    finalColor += emission;

                    float timeLight = saturate((1 - abs(frac(uv.y + _Time.y * _TimeLightSpeed) - 0.5) * 2) - (1 - _TimeLightWidth)) * (1 / _TimeLightWidth);
                    finalColor += timeLight * _TimeLightColor.rgb * _TimeLightStr * faceTex.g;

                    float3 rim = pow(1 - saturate(dot(N, viewDirWS)), _FalloffLevel) * _ColorF.rgb * _ColorF.a;
                    finalColor += rim * _EffectWeight;

                    #ifdef _ALPHATEST_ON
                    clip(albedoAlpha - _Cutoff);
                    #endif

                    float alpha = albedoAlpha * _CharacterAlpha * faceTex.a;
                    clip(faceTex.a - 0.1);

                    //UNITY_APPLY_FOG(i.fogCoord, finalColor);
                    return half4(finalColor, alpha);
                }
                else
                {
                    float4 hairTex = SAMPLE_TEXTURE2D(_MainTexHair, sampler_MainTexHair, uv);
                    float3 N = normalWS;
                    float3 T = binormalWS;

                    float3 hairColor1 = lerp(_HairColor1st.rgb, _HairAO1st.rgb, 1 - i.color.r) * i.color.g;
                    float3 hairColor2 = lerp(_HairColor2ed.rgb, _HairAO2ed.rgb, 1 - i.color.r) * (1 - i.color.g);
                    float3 hairColor = hairTex.r * (hairColor1 + hairColor2);

                    float shift = _HairPrimaryShift + hairTex.g;
                    float3 shiftedTangent = ShiftTangent1(T, N, shift);
                    float spec = StrandSpecular(shiftedTangent, viewDirWS, L, _HairSpeScal);
                    float3 specColor1 = spec * _HairSpecular1st.rgb * _HairSpecular1st.a * lightColor * i.color.b;
                    float3 specColor2 = spec * _HairSpecular2ed.rgb * _HairSpecular2ed.a * lightColor * i.color.b;

                    float NdotL = saturate(dot(N, L));
                    hairColor *= NdotL * 0.35 + 0.65;
                    float3 finalColor = hairColor * lightColor * 2 + (specColor1 + specColor2) * hairTex.g;

                    #ifdef _ALPHATEST_ON
                    clip(hairTex.a - _Cutoff);
                    #endif

                    float alpha = hairTex.a * _Color.a * _CharacterAlpha;
                    //UNITY_APPLY_FOG(i.fogCoord, finalColor);
                    return half4(finalColor, alpha);
                }
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}