//https://zhuanlan.zhihu.com/p/575096572 搜索 高光周围加色
Shader "Art_URP/Base/NPR/StylizedHighlightSpread"
{
    Properties
    {
        _BaseColor("BaseColor" , Color) = (0,0,0,1)

        [Space(10)]
        [Header(Specular)]
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _SpecularScale ("Specular Scale", Range(0,1)) = 0.01
        _SpecularSmooth ("Specular Smooth", Range(0,1)) = 0.001

        [Space(10)]
        [Header(Spread)]
        _SpreadColor ("Spread Color", Color) = (1,0,0,1)
        _SpreadScale ("Spread Scale", Range(0,1)) = 0.001
       	_SpreadSmooth ("Spread Smooth", Range(0, 1)) = 0.3
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
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 normalWS     : TEXCOORD0;
                float3 viewWS       : TEXCOORD1;
            };
            
            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                half _SpecularScale;
                half _SpecularSmooth;
                half4 _SpecularColor;
                half _SpreadSmooth;
                half4 _SpreadColor;
                half _SpreadScale;
            CBUFFER_END

            half StylizedHighlightScale(half3 lightDirWS , half3 normalWS , half3 viewWS , half highlightScale)
            {
                half3 halfDir = normalize(lightDirWS + viewWS);
                half NdotH = saturate(dot(normalWS,halfDir));
                // half smoothness = exp2(10 * highlightScale + 1);
                // half modifier = pow(NdotH , highlightScale);

                half modifier = NdotH * (highlightScale + 0.5);

                return modifier;
            }

            half3 StylizedHighlightSmoothLerp(half3 startColor , half3 endColor , half smooth , half lerpDelta)
            {
                half colorLerpDelta = smoothstep(0.5 - smooth * 0.5,0.5 + smooth * 0.5,lerpDelta);
                half3 finialColor = lerp(startColor,endColor,colorLerpDelta);
                return finialColor;
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
                half3 lightDir = light.direction;

                half3 worldNormalDir = normalize(i.normalWS);
                half3 worldViewDir = normalize(i.viewWS);

                //spreadColor扩散颜色
                //将扩散的高光和基础颜色插值在一起
                half spreadDelta = StylizedHighlightScale(lightDir,worldNormalDir, worldViewDir,_SpreadScale);
                half3 spreadColor = StylizedHighlightSmoothLerp(_BaseColor.rgb,_SpreadColor.rgb * lightColor,_SpreadSmooth,spreadDelta);

                //将正常的高光和上一步的结果插值在一起
                half specularDelta = StylizedHighlightScale(lightDir,worldNormalDir, worldViewDir,_SpecularScale);
                half3 finalSpecularColor = StylizedHighlightSmoothLerp(spreadColor.rgb,_SpecularColor.rgb * lightColor,_SpecularSmooth,specularDelta);


                FinalColor = half4(finalSpecularColor , 1);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
