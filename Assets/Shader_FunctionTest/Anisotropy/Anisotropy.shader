Shader "Art_URP/FunctionTest/Anisotropy"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _FlowMap ("Flow Map", 2D) = "white" { }

        _NoiseTex ("Nosie Tex", 2D) = "black" { }
        _AnisoNoiseStrength ("_Aniso Noise Strength", Range(0, 1)) = 0.3
        _AnisoShift ("Anisotropy Shift", Range(-2, 2)) = 0      //偏移
        _AnisoSpecPower ("Anisotropy Specular Power", Range(0, 500)) = 10
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}
        
        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
            };
            
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 positionWS   : TEXCOORD1;
                float3 tangentWS    : TEXCOORD2;
                float3 bitangentWS  : TEXCOORD3;
                float3 normalWS     : TEXCOORD4;
                float3 viewWS       : TEXCOORD5;
            };

            TEXTURE2D(_FlowMap);SAMPLER(sampler_FlowMap);
            TEXTURE2D(_NoiseTex);SAMPLER(sampler_NoiseTex);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _FlowMap_ST;
                float4 _NoiseTex_ST;
                float4 _Color;
                float  _AnisoNoiseStrength;
                float  _AnisoShift;
                float  _AnisoSpecPower;
            CBUFFER_END
            
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS);
                o.positionHCS = vertexInput.positionCS;
                o.positionWS = vertexInput.positionWS;

                o.normalWS = normalInput.normalWS;
                o.tangentWS = normalInput.tangentWS;
                o.bitangentWS = normalInput.bitangentWS;

                o.viewWS = GetWorldSpaceViewDir(o.positionWS);

                 o.uv = v.texcoord;
                
                return o;
            }
            
            // // ------------Anisotropy---------------------------
            half3 CustomShiftTangent(half3 T, half3 N, half shift)
            {
                return normalize(T + shift * N);
            }
            half AnisotropyKajiyaKay(half3 T, half3 V, half3 L, half specPower)
            {
                half3 H = normalize(V + L);
                half  HdotT = dot(T, H);
                half  sinTH = sqrt(1 - HdotT * HdotT);
                half  dirAtten = smoothstep(-1, 0, HdotT);
                
                return dirAtten * saturate(pow(sinTH, specPower));
            }
            
            half4 frag(Varyings i) : SV_Target
            {
                half4 FinalColor;
                //光照相关信息
                Light light = GetMainLight();
                half3 lightColor = light.color * light.distanceAttenuation;   
                half3 worldLightDir = light.direction;

                half3 worldViewDir = SafeNormalize(i.viewWS);
                
                float3 worldTangentDir = normalize(i.tangentWS);
                float3 worldBitangentDir = normalize(i.bitangentWS);
                float3 worldNormalDir = normalize(i.normalWS);
                
                // float2 anisoFlowmap = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap , i.uv).rg;     //使用一张uv效果的贴图来作为flowMap
                float2 anisoFlowmap = i.uv;                                                         //直接使用计算一个效果uv的
                anisoFlowmap = anisoFlowmap * 2 - 1;

                float shiftNoise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex , i.uv).r;
                shiftNoise = (shiftNoise * 2 - 1) * _AnisoNoiseStrength;

                worldTangentDir = normalize(anisoFlowmap.x * worldTangentDir + anisoFlowmap.y * worldBitangentDir);

                //_AnisoShift偏移各向异性的位移
                worldTangentDir = CustomShiftTangent(worldTangentDir, worldNormalDir, _AnisoShift + shiftNoise);
                half anisoSpec = AnisotropyKajiyaKay(worldTangentDir ,worldViewDir, worldLightDir, _AnisoSpecPower);

                // ================================ Diffuse Specular ================================
                half diffuse_term = max(0, dot(worldNormalDir, worldLightDir));
                half half_limbert = diffuse_term * 0.5 + 0.5;
                
                half3 diffuse = _Color.rgb * half_limbert * lightColor;

                FinalColor = half4(anisoSpec + diffuse , 1.0);
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
