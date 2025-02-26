Shader "Catlikecoding/FirstLight"
{
    Properties
    {
        _Color("Color" , Color) = (1,1,1,1)
        _BaseMap ("BaseMap", 2D) = "white" {}
        _SpecularColor("SpecularColor",Color) = (1,1,0,0)
        _Smoothness("Smoothness",Range(0,1)) = 0.5
        _Metallic("Metallic",Range(0,1)) = 0

    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            //顶点着色器输入结构体
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 texcoord     : TEXCOORD;
            };
            //顶点着色器输出结构体
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD;
                float3 normalWS     : TEXCOORD1;
                float3 viewWS       : TEXCOORD2;
            };

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _BaseMap_ST;
                float4 _SpecularColor;
                float  _Smoothness;
                float  _Metallic;
            CBUFFER_END

            //顶点着色器
            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings) 0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS);

                o.positionHCS = vertexInput.positionCS;
                o.normalWS = normalInput.normalWS;
                o.viewWS = GetWorldSpaceViewDir(vertexInput.positionWS);

                o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
                return o;
            }

            //像素着色器
            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                Light light = GetMainLight();
                half4 lightColor = half4(light.color * light.distanceAttenuation, 1.0);
                half3 lightDirWS = light.direction;

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap , i.uv);
                baseMap *= 1 - max(_SpecularColor.r , max(_SpecularColor.g , _SpecularColor.b));

                half3 worldNormalDir = normalize(i.normalWS);
                half3 worldViewDir = normalize(i.viewWS);
                half3 reflectionDir = reflect(-lightDirWS,worldNormalDir);
                half3 halfDir = saturate(normalize(lightDirWS + worldViewDir));
                
                half lambert = saturate(dot(lightDirWS,worldNormalDir));
                half blinnPhone = pow(saturate(dot(halfDir,worldNormalDir)) , _Smoothness * 100 + 0.001);

                half4 diffuse =  baseMap * _Color * lightColor * lambert;
                half4 specular = _SpecularColor * lightColor * blinnPhone;

                FinalColor = diffuse + specular;
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
