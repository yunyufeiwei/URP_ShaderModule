Shader "Unlit/Hair2_URP"
{
    Properties
    {
        _MainColor("MainColor", Color) = (1,1,1,1)
        _BackColor("BackColor",Color) = (1,1,1,1)
        _HairTex("Texture", 2D) = "white" {}
        
        Specular1Color("Specular1Color", Color) = (0.0,0.0,0.0,0.0)
        _PrimaryShift("PrimaryShift", Range(0, 1)) = 0.0
        
        _SpecularRange("SpecularRange", Range(0, 256)) = 20
        _SpecularPower("SpecularPower", Range(0, 5)) = 1

        [Header(SpecularMask)]
        _SpecularMask("SpecularMask",2D) = "white"{}
        
        [Header(OtherGloss)]
        _Gloss("Gloss",Range(0,1)) = 1
        _GlossColor("GlossColor",Color) = (1,1,1,1)
        
        [Header(Normal)]
        _NormalTex("NormalTexture", 2D) = "white" {}
        _NormalPower("NormalPower",Range(0,2)) = 1
        _Alpha("Alpha",Range(0,1)) = 1
        _LightPower("LightPower",Range(1,10))=1
        
        [Header(Ramp)]
        _RampTexture("Ramp",2D) = "white"{}
        _GlossMask("GlossMask",2D) = "white"{}
        
        [Header(Fresnel)]
        _FresnelPower("FresnelPower",Range(0,2))= 1
        _FresnelRange("FresnelRange",Range(0,10))= 1
        _FresnelColor("FresnelColor",Color ) = (1,1,1,1)
        
        [Header(Fresnel2)]
        _FresnelPower2("FresnelPower2",Range(0,2))= 1
        _FresnelRange2("FresnelRange2",Range(0,10))= 1
        _FresnelColor2("FresnelColor2",Color ) = (1,1,1,1)
        
        [Header(Rampmask)]
        _UVRampColor("UVRampColor",Color) = (1,1,1,1)
        _UVRampPower("UVRampPower",Range(0,1)) = 1
    }

    SubShader
    {
        Tags{ "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }
        Pass
        {
            Tags {"RenderType"="Opaque"}
            ZWrite On
            ColorMask 0
        }

        Pass
        {
            Tags{ "LightMode"="UniversalForward" }

            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _MainColor;
                half4 _BackColor;
                float4 _HairTex_ST;
                half4 Specular1Color;
                half _PrimaryShift;
                half _SpecularRange;
                half _SpecularPower;
                float4 _SpecularMask_ST;
                half _Gloss;
                half4 _GlossColor;
                float4 _NormalTex_ST;
                half _NormalPower;
                half _Alpha;
                half _LightPower;
                float4 _RampTexture_ST;
                float4 _GlossMask_ST;
                half _FresnelPower;
                half _FresnelRange;
                half4 _FresnelColor;
                half _FresnelPower2;
                half _FresnelRange2;
                half4 _FresnelColor2;
                half4 _UVRampColor;
                half _UVRampPower;
            CBUFFER_END

            TEXTURE2D(_HairTex);
            SAMPLER(sampler_HairTex);
            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_NormalTex);
            TEXTURE2D(_SpecularMask);
            SAMPLER(sampler_SpecularMask);
            TEXTURE2D(_RampTexture);
            SAMPLER(sampler_RampTexture);
            TEXTURE2D(_GlossMask);
            SAMPLER(sampler_GlossMask);

            struct Attributes
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 tangent : TANGENT;
            };

            struct Varyings
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 posWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 tangentWS : TEXCOORD3;
                float3 binormalWS : TEXCOORD4;
                //UNITY_FOG_COORDS(5)
                float face : TEXCOORD6;
            };

            Varyings vert(Attributes v)
            {
                Varyings o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _HairTex);
                o.posWS = TransformObjectToWorld(v.vertex.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normal);
                o.tangentWS = TransformObjectToWorldDir(v.tangent.xyz);
                o.binormalWS = cross(o.normalWS, o.tangentWS);
                o.face = v.normal.w;
                //UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                Light mainLight = GetMainLight();
                half3 L = normalize(mainLight.direction);
                half3 V = normalize(GetWorldSpaceViewDir(i.posWS));
                half3 N = normalize(i.normalWS);
                half3 T = normalize(i.tangentWS);
                half3 B = normalize(i.binormalWS);
                half3 R = normalize(L + V);

                float3 anisoNormal = normalize(lerp(N + B, B, _PrimaryShift));
                float anisoDot = dot(anisoNormal, R);
                half4 specular = half4(mainLight.color * Specular1Color.rgb * pow(max(0, sqrt(1 - anisoDot * anisoDot)), _SpecularRange), 1);

                float3 normalTex = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv));
                float3x3 tangentMat = float3x3(T * _NormalPower, B * _NormalPower, N);
                float3 normalWS = normalize(mul(normalTex, tangentMat));

                half NdotL = saturate(dot(L, normalWS) * 0.5 + 0.5);
                half4 ramp = SAMPLE_TEXTURE2D(_RampTexture, sampler_RampTexture, float2(NdotL, NdotL));

                half4 specMask = SAMPLE_TEXTURE2D(_SpecularMask, sampler_SpecularMask, i.uv);
                half gloss = pow(max(0, dot(N, normalize(V + L))), exp2(_Gloss * 10 + 1));
                half4 glossMask = SAMPLE_TEXTURE2D(_GlossMask, sampler_GlossMask, i.uv);

                half3 uvRamp = lerp(1, _UVRampColor.rgb, (1 - glossMask.r) * _UVRampPower);

                half4 hairTex = SAMPLE_TEXTURE2D(_HairTex, sampler_HairTex, i.uv);
                half4 color = hairTex * _MainColor;
                half4 glossOut = (gloss * _GlossColor + (NdotL * specular * specMask.r * _SpecularPower)) * glossMask.g;
                color += glossOut;
                color.rgb *= uvRamp;

                half3 lightColor = lerp(_BackColor.rgb, _MainColor.rgb, ramp.r);

                half rim = 1.0 - saturate(dot(normalWS, V));
                half3 fresnel = pow(rim, _FresnelRange) * _FresnelPower * _FresnelColor.rgb;
                half3 fresnel2 = pow(rim, _FresnelRange2) * _FresnelPower2 * _FresnelColor2.rgb;

                half4 final;
                final.rgb = lightColor * color.rgb * mainLight.color + fresnel + fresnel2;
                final.a = hairTex.a * _Alpha;

                //UNITY_APPLY_FOG(i.fogCoord, final.rgb);
                clip(hairTex.a - 0.01);

                return i.face >= 0 ? final : color * 0.5;
            }
            ENDHLSL
        }

        Pass
        {
            Tags { "LightMode"="SRPDefaultUnlit" }
            Blend One One
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _HairTex_ST;
            half4 _MainColor;
            half _LightPower;
            CBUFFER_END

            TEXTURE2D(_HairTex);
            SAMPLER(sampler_HairTex);

            struct Attributes
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 posWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                //UNITY_FOG_COORDS(3)
            };

            Varyings vert(Attributes v)
            {
                Varyings o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _HairTex);
                o.posWS = TransformObjectToWorld(v.vertex.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normal);
                //UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                Light light = GetAdditionalLight(0, i.posWS);
                half3 N = normalize(i.normalWS);
                half NdotL = saturate(dot(N, light.direction) * 0.5 + 0.5);
                half4 hair = SAMPLE_TEXTURE2D(_HairTex, sampler_HairTex, i.uv);
                half3 col = hair.rgb * NdotL * light.color * light.shadowAttenuation;
                //UNITY_APPLY_FOG(i.fogCoord, col);
                return half4(col, hair.a);
            }
            ENDHLSL
        }
    }
}