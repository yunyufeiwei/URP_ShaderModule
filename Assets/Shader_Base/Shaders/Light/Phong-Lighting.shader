//法国计算机科学家Henri Gouraud(亨利，高洛德)在1971发表的精华着色算法，后来被称为Gouraud着色。将着色计算放在了顶点部分。
//美国点奥CG研究学者，Bui Tuong Phong，在1973年的论文中发表了Phong着色法。该方法类似于Gouraud着色，但其将光照计算放在了像素阶段完成，而非顶点阶段。
//Phong-Light是完整的光照模型，而PhongSpecular仅仅是高光表现部分

Shader "Art_URP/Base/Light/Phont-Light"
{
    Properties
    {
        _BaseColor("BaseColor",Color) = (1,1,1,1)
        _SpecularColor("SpecularColor" , Color) = (1,1,1,1)
        _SpecularPow("SpecularPow" , Range(8,255)) = 20
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
                float3 normalWS     : TEXCOORD;
                float3 viewWS       : TEXCOORD1;
            };
            
            CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor;
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

                //获取光照部分信息
                Light light = GetMainLight();
                half3 lightColor = light.color * light.distanceAttenuation;;
                half3 lightDir = light.direction;

                half3 worldNormalDir = normalize(i.normalWS);
                half3 worldViewDir = normalize(i.viewWS);
                half3 reflectDir = normalize(reflect(-lightDir , worldNormalDir));

                half3 diffuseColor = lightColor * _BaseColor.rgb * saturate(dot(lightDir , worldNormalDir));
                half3 specularColor = lightColor *  _SpecularColor.rgb * pow(saturate(dot(reflectDir , worldViewDir)) , _SpecularPow);

                FinalColor = half4(diffuseColor + specularColor , 1);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
