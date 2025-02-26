
Shader "Art_URP/Base/NPR/ToneBaseShading"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _WarmColor ("Warm Color(暖色调)", Color) = (1,1,1,1)
        _CoolColor ("Cool Color(冷色调)", Color) = (1,1,1,1)
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _Smoothness ("Smoothness", Range(8,255)) = 20
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
                float4 _BaseColor;
                half4 _WarmColor;
                half4 _CoolColor;
                half4 _SpecularColor;
                half _Smoothness;
            CBUFFER_END

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
                half3 lightDir = light.direction;

                half3 ambientColor = unity_AmbientSky.rgb;

                half3 worldNormalDir = normalize(i.normalWS);
                half3 worldViewDir = normalize(i.viewWS);

                half NdotL = dot(worldNormalDir,-lightDir);
                half3 halfDir = SafeNormalize(lightDir + worldViewDir);
                half NdotH = dot(worldNormalDir , halfDir);

                //https://users.cs.northwestern.edu/~ago820/thesis/node26.html
                half coolAlpha = _CoolColor.a;
                half warmBeta = _WarmColor.a;

                //Kd为黑色到自身颜色的渐变，相当于漫反射颜色
                half3 Kd = _BaseColor * (1 - NdotL) + half3(0,0,0) * NdotL;
                //根据参考文档kBlue对应的是冷色调，kYellow对应的是暖色调 kBlue = (0,0,b) kYellow =(y,y,0)
                //这里直接用2个color表示了，kBlue = _CoolColor.rgb, kYellow = _WarmColor.rgb;
                //可以看到这个公式等于将一个冷色调到暖色调的ramp和一个物体背光面到向光面颜色的Ramp相加的结果(Ramp)
                half3 kCool = _CoolColor.rgb + coolAlpha * Kd;      
                half3 kWarm = _WarmColor.rgb + warmBeta * Kd;

                half3 diffuseColor = ((1 + NdotL) / 2) * kCool + (1 - (1 + NdotL) / 2) * kWarm;
                half3 specularColor = LightingSpecular(lightColor,lightDir,worldNormalDir,worldViewDir,_SpecularColor,_Smoothness);
                
                FinalColor = half4(ambientColor + diffuseColor + specularColor,1);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
