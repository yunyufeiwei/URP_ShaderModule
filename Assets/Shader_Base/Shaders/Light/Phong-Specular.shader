Shader "Art_URP/Base/Light/Phong-Specular"
{
    Properties
    {
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
            };
            
            CBUFFER_START(UnityPerMaterial)
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

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;
                Light light = GetMainLight();
                half3 lightColor = light.color * light.distanceAttenuation;
                half3 lightDirWS = light.direction;

                half3 worldNormalDir = normalize(i.normalWS);
                half3 ViewDir = normalize(i.viewDirWS);

                //Phong 
                half3 reflectDir = normalize(reflect(-lightDirWS , worldNormalDir));
                half3 specular = lightColor * _SpecularColor.rgb * pow(saturate(dot(reflectDir , ViewDir)) , _SpecularGloss);

                FinalColor = half4(specular , 1);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
