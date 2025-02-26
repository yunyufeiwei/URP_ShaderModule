Shader "Art_URP/FunctionTest/WrapLighting"
{
    Properties
    {
        _Diffuse("Diffuse" , Color) = (1,1,1,1)
        _SSSDistortion ("SSS Distortion", Range(0, 1)) = 1
        _Power ("Power", Float) = 1
        _Scale ("Scale", Float) = 1
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        LOD 100

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 normalWS     : NORMAL;
                float3 positionWS  : TEXCOORD1;
            };
            
            
            CBUFFER_START(UnityPerMaterial)
                float4 _Diffuse;
                float  _SSSDistortion;
                float  _Power;
                float  _Scale;
            CBUFFER_END

            half3 computeSSS(Light light, float3 normal, float3 viewDir)
            {
                half3 lightDir = normalize(light.direction);
                half3 dir = normalize(lightDir + normal * _SSSDistortion);
                half3 sss = _Diffuse.rgb * light.color * pow(saturate(dot(viewDir, -dir)), _Power) * _Scale;
                
                return sss;
            }

            float3 LightingBased(Light light , half3 normalWS , half3 viewDirWS)
            {
                half3 lightDirWS = normalize(light.direction);
                half  diff = saturate(dot(normalWS , lightDirWS));
                half3 diffuse  = light.color * _Diffuse.rgb * diff;
                half3 sss = computeSSS(light , normalWS , viewDirWS);

                return (diffuse + sss) * light.distanceAttenuation * light.shadowAttenuation;
            }

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);   //vertexInput返回值里面包含了世界空间、视口空间、裁剪空间、NDC空间
                o.positionWS = vertexInput.positionWS;
                o.positionHCS = vertexInput.positionCS;
                
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                Light mainLight = GetMainLight();
                half3 lightDirWS = normalize(mainLight.direction);
                half3 normalWS = normalize(i.normalWS);
                half3 viewDirWS = normalize(GetCameraPositionWS() - i.positionWS);

                half3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * _Diffuse.rgb;

                half  diff = saturate(dot(normalWS, lightDirWS));
                half3 diffuse = mainLight.color * _Diffuse.rgb * diff;

                half3 sss = computeSSS(mainLight , normalWS , viewDirWS);
                
                half3 FinalColor = ambient + diffuse + sss;
                
                uint pixelLightCount = GetAdditionalLightsCount();
                for (uint lightIndex = 0; lightIndex < pixelLightCount; ++ lightIndex)
                {
                    Light light = GetAdditionalLight(lightIndex, i.positionWS);
                    FinalColor += LightingBased(light, normalWS , viewDirWS);
                }

                return half4(FinalColor , 1.0);
            }
            ENDHLSL
        }
    }
}
