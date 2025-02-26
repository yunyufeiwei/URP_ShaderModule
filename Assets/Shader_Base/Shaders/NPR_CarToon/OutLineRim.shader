//外描边本质上来说是利用模型法线和视角向量的夹角大小来计算描边效果，类似于菲涅尔效果
// 参考资料：
//https://zhuanlan.zhihu.com/p/129291888
//https://zhuanlan.zhihu.com/p/26409746



Shader "Art_URP/Base/NPR/OutlineRim"
{
    Properties
    {
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _OutlineWidth ("Outline Width",Range(0,1)) = 0.5
        _OutlineSoftness("OutlineSoftness",float) =0.01
        _OutlineSmoothness("Outline Smoothness",Range(8,255)) = 20
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
                float4 _OutlineColor;
                float  _OutlineWidth;
                float  _OutlineSoftness;
                float  _OutlineSmoothness;
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

                half NdotV = saturate(dot(worldNormalDir,worldViewDir));

                //Fresnel方式计算
                half  edge1 = 1 - _OutlineWidth;
                half  edge2 = edge1 + _OutlineSoftness;
                half  fresnel = pow((1.0 - NdotV) , _OutlineSmoothness);
                half3 fresnelColor = lerp(1 , smoothstep(edge1,edge2,fresnel) , step(0,edge1)) * _OutlineColor;

                FinalColor = half4(fresnelColor ,1);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
