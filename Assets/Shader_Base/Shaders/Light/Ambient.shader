Shader "Art_URP/Base/Light/Ambient"
{
    Properties
    {
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
            };
            
            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END

            half4 CalculateGradientAmbient(float3 normalWS)
            {
                //unity_AmbientSky、unity_AmbientEquator、unity_AmbientGround代码在UnityInput.hlsl中
                //---\Library\PackageCache\com.unity.render-pipelines.universal@14.0.8\ShaderLibrary\UnityInput.hlsl
                half4 ambientColor = lerp(unity_AmbientEquator,unity_AmbientSky,saturate(normalWS.y));
                ambientColor = lerp(ambientColor,unity_AmbientGround,saturate(-normalWS.y));
                return ambientColor;
            }

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;

                half3 worldNormalDir = normalize(i.normalWS);

                //real4 unity_AmbientSky、unity_AmbientEquator、unity_AmbientGround 被定义在 UnityInput.hlsl
                //路径：\Library\PackageCache\com.unity.render-pipelines.universal@14.0.8\ShaderLibrary\UnityInput.hlsl

                //half3 ambientColor = half3(unity_SHAr.w , unity_SHAg.w , unity_SHAb.w)，使用该代码可以对Skybox、Gradient、color源模式下的环境光进行调整,但在Bake光照后失效
                // half3 ambientColor = half3(unity_SHAr.w , unity_SHAg.w , unity_SHAb.w);

                //使用下面的代码，当Source维Skybox时，强度系数不产生作用（Intensity Multiplier）
                // half3 ambientColor = unity_AmbientSky;

                //half3 ambientColor = _GlossyEnvironmentColor.xyz;可以对Skybox、Gradient、color源模式下的环境光进行调整，且Bake之后仍然生效，但在Gradient模式下，上下的颜色不太明显区分
                half4 ambientColor = _GlossyEnvironmentColor;

                //通过顶点法线来混合Granient的颜色，仅作为参考方向
                // half3 ambientColor = CalculateGradientAmbient(worldNormalDir);

                

                FinalColor = ambientColor;

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
