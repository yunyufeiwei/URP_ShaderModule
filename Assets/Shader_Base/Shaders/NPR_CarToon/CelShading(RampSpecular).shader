//在Ramp漫反射基础上，添加了高光部分(同样使用Ramp贴图进行映射)
//这里使用的是两张Ramp贴图，可以把高光部分也和漫反射部分合在一张图上，即Ramp贴图的u方向[0,x]表示漫反射，[x,1]表示高光

Shader "Art_URP/Base/NPR/CelShading-RampSpecular"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        [NoScaleOffset]_RampMap("RampMap" , 2D) = "white"{}
        _SpecularColor("SpecularColor",Color)=(1,1,1,1)
        [NoScaleOffset]_SpecularRamp("SpecularRamp",2D)="white"{}
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
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS     : POSITION;
                float3 normalOS       : NORMAL;
                float2 texcoord       : TEXCOORD;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD;
                float3 normalWS     : TEXCOORD1;
                float3 viewWS       : TEXCOORD2;
            };
            
            TEXTURE2D(_RampMap);SAMPLER(sampler_RampMap);
            TEXTURE2D(_SpecularRamp);SAMPLER(sampler_SpecularRamp);

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _SpecularColor;
                float  _SpecularPow;
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

                half3 worldNormalDir = normalize(i.normalWS);
                half3 worldViewDir = normalize(i.viewWS);
                half3 halfDir = normalize(lightDir + worldViewDir);

                //Lambert
                half lambert = saturate(dot(worldNormalDir,lightDir));
                half2 rampUV = half2(lambert,lambert);
                //使用lambert得到的[0-1]的范围作为Ramp贴图采样的uv，所以Ramp纹理左边最黑的地方也就是背光面，最后边也是最亮的地方，就是向光面
                half4 baseMap = SAMPLE_TEXTURE2D(_RampMap , sampler_RampMap , rampUV);

                half3 diffuseColor = baseMap.rgb * _Color;

                half blinnPhong = pow(saturate(dot(worldNormalDir,halfDir)) , _SpecularPow);
                half2 SpecularUV = half2(blinnPhong,blinnPhong);
                half4 specularRamp = SAMPLE_TEXTURE2D(_SpecularRamp,sampler_SpecularRamp,SpecularUV);

                half3 specularColor = specularRamp.rgb * _SpecularColor;



                FinalColor = half4(diffuseColor + specularColor , 1);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
