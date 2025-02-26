Shader "Art_URP/Base/Light/MultiLighting"
{
    Properties
    {
        _BaseColor("BaseColor",Color) = (1,1,1,1)
        _SpecularColor("SpecularColor",Color) = (1,1,1,1)
        _SpecularPow("SpecularPow",Range(8,255)) = 20
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}
        LOD 100

        pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS     : POSITION;
                float3 normalOS       : NORMAL;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 positionWS   : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 viewWS       : TEXCOORD2;
            };
            
            CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor;
            float4 _SpecularColor;
            float  _SpecularPow;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.viewWS = GetWorldSpaceViewDir(o.positionWS);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;
                Light light = GetMainLight();
                half3 lightColor = light.color * light.distanceAttenuation;
                half3 lightDir = light.direction;

                half3 ambientColor = _GlossyEnvironmentColor.xyz;

                half3 worldNormalDir = normalize(i.normalWS);
                half3 worldViewDir = normalize(i.viewWS);

                half3 diffuseColor = LightingLambert(lightColor , lightDir , worldNormalDir) * _BaseColor.rgb;
                half3 specularColor = LightingSpecular(lightColor , lightDir , worldNormalDir , worldViewDir , _SpecularColor , _SpecularPow);

                int additionalLightCount = GetAdditionalLightsCount(); //获取额外光源数量
                for(int j = 0; j < additionalLightCount; ++j)
                {
                    light = GetAdditionalLight(j,i.positionWS);     //根据Index获取额外的光源数据
                    half3 attenuatedLightColor = light.color * light.distanceAttenuation;
                    //叠加漫反射和高光
                    diffuseColor += LightingLambert(attenuatedLightColor , light.direction , worldNormalDir);
                    specularColor += LightingSpecular(attenuatedLightColor , light.direction , worldNormalDir , worldViewDir , _SpecularColor , _SpecularPow);
                }

                FinalColor = half4(ambientColor + diffuseColor + specularColor , 1);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
