Shader "Art_URP/Base/NPR/CelShading-RampFresnel"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _Ramp("Ramp",2D) = "whtie"{}
        _Fresnel("Fresnel",Range(0,2)) = 1
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
            
            TEXTURE2D(_Ramp);SAMPLER(sampler_Ramp);

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float  _Fresnel;
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

                half lambert = saturate(dot(worldNormalDir,lightDir));
                half fresnel = saturate(dot(worldNormalDir,worldViewDir) * _Fresnel);

                //U方向使用纹理贴图的左右过渡，V方向使用纹理贴图的上下渐变，将其构造成uv来采样贴图
                half2 rampUV = half2(lambert,fresnel);
                half4 baseMap = SAMPLE_TEXTURE2D(_Ramp,sampler_Ramp , rampUV);

                half3 diffuseColor = baseMap.rgb * _Color;

                FinalColor = half4(diffuseColor , 1);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
