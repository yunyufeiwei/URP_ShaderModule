Shader "Art_URP/Base/Light/GouraudLight"
{
    Properties
    {
        _BaseColor("BaseColor" , Color) = (1,1,1,1)
        _SpecularColor("SpecularColor" , Color) = (1,1,1,1)
        [PowerSlider(8)]_SpecularGloss("SpecularGloss" , Range(2,20))= 2
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
                float3 viewDirWS    : TEXCOORD1;
                float3 normalWS     : TEXCOORD2;
                float4 finalColor   : TEXCOORD3;
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _SpecularColor;
                float  _SpecularGloss;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.viewDirWS = GetWorldSpaceViewDir(o.positionWS);

                Light light = GetMainLight();
                half3 lightColor = light.color * light.distanceAttenuation;
                half3 lightDirWS = light.direction;

                half3 worldNormalDir = normalize(o.normalWS);
                half3 ViewDir = normalize(o.viewDirWS);

                //Phong 
                half3 reflectDir = normalize(reflect(-lightDirWS , worldNormalDir));

                half3 diffuseColor = lightColor * _BaseColor.rgb * saturate(dot(worldNormalDir , lightDirWS));
                half3 specularColor = lightColor * _SpecularColor.rgb * pow(saturate(dot(reflectDir , ViewDir)) , _SpecularGloss);

                o.finalColor = half4(diffuseColor + specularColor , 1);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                return i.finalColor;
            }
            ENDHLSL  
        }
    }
}
