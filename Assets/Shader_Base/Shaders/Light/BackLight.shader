Shader "Art_URP/Base/Light/BackLight"
{
    Properties
    {
        _Distortion("Distortion" , float) = 0.5
        _Power("Power",Range(0 , 2)) = 1.5
        _Scale("Scale" , float) =1

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
                float3 normalWS     : TEXCOORD0;
                float3 viewWS       : TEXCOORD1;
            };
            
            CBUFFER_START(UnityPerMaterial)
            float _Distortion;
            float _Power;
            float _Scale;
            CBUFFER_END

            half LightingBackLight(half3 lightDirWS , half3 normalWS , half3 viewDirWS , half distortion , half power , half scale)
            {
                //沿着光线方向上偏移法线，最后在取反
                half3 N_shift = -normalize(normalWS * _Distortion + lightDirWS);
                half  backLight =saturate(pow(saturate(dot(N_shift,viewDirWS)) , power) * scale );
                return backLight;
            }

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.viewWS = GetWorldSpaceViewDir(positionWS);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;
                Light light = GetMainLight();
                half3 lightColor = light.color * light.distanceAttenuation;
                half3 lightDirWS = light.direction;

                // half3 N_shift = -normalize(i.normalWS * _Distortion + lightDirWS);
                // half3 backLight =lightColor * saturate(pow(saturate(dot(N_shift,i.viewWS)) , _Power) * _Scale );
                half3 backLight = LightingBackLight(lightDirWS , i.normalWS , i.viewWS , _Distortion , _Power , _Scale) * lightColor;

                FinalColor = half4(backLight ,1);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
