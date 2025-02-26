Shader "Art_URP/Scene/Masonry"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _RefractTex("RefractTex" , Cube) = "white"{}
        _RefractIntensity("RefractIntensity" , float) = 1
        _ReflectTex("ReflectTex" , Cube) = "white"{}
        _ReflectIntensity("ReflectIntensity" , float) = 1
        _FresnelPower("FresnelPower" , Range(1,20))=2
        _RimScale("RimScale" , float) = 1
        _RimColor("RimColor" , Color) = (1,1,1,1)
        _Alpha("Alpha" , Range(0,1)) = 1

        //也可以使用半透明混合方式，但性能消耗会变大
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcFactor("SrcFactor",int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]_DstFactor("DstFactor",int) = 0
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque"  "Queue" = "Geometry"} 
        // Tags{"RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent"  "Queue" = "Transparent"} 
        
        pass
        {
            Blend [_SrcFactor][_DstFactor]
            ZWrite Off
            Cull Front
        
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD;
                float3 normalOS     : NORMAL;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD;
                float3 positionWS   : TEXCOORD1;
                float3 normalWS     : TEXCOORD2;
                float3 viewWS       : TEXCOORD3;
            };
            
            TEXTURECUBE(_RefractTex);SAMPLER(sampler_RefractTex);
            TEXTURECUBE(_ReflectTex);SAMPLER(sampler_ReflectTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float  _RefractIntensity;
                float  _ReflectIntensity;
                float  _FresnelPower;
                float4 _RimColor;
                float  _RimScale;
                float  _Alpha;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.viewWS = GetWorldSpaceViewDir(o.positionWS);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;

                half3 ambientColor =  _GlossyEnvironmentColor.rgb;

                Light light = GetMainLight(TransformWorldToShadowCoord(i.positionWS));
                half3 lightColor = light.color * light.distanceAttenuation;
                half3 lightDir = light.direction;

                half3 worldViewDir = SafeNormalize(i.viewWS);
                half3 worldNormalDir = normalize(i.normalWS);

                half3 reflectDir = normalize(reflect(-worldViewDir , worldNormalDir));
                half4 refractTex = SAMPLE_TEXTURECUBE_LOD(_RefractTex , sampler_RefractTex , reflectDir , 2);
                half4 reflectTex = SAMPLE_TEXTURECUBE_LOD(_ReflectTex , sampler_ReflectTex , reflectDir , 2);

                half3 refractColor = refractTex.rgb * _Color * _RefractIntensity;
                half3 reflectColor = reflectTex.rgb * _ReflectIntensity;

                //fresnelColor
                half fresnelFactor = max(0.0 , pow((1 - saturate(dot(worldNormalDir , worldViewDir))) , _FresnelPower)) * _RimScale;
                half3 fresnelColor = fresnelFactor * _RimColor;

                FinalColor = half4(refractColor * reflectColor  , _Alpha);
                // FinalColor = half4(fresnelColor , 1);

                return FinalColor;
            }
            ENDHLSL  
        }
        pass
        {
            Blend [_SrcFactor][_DstFactor]
            ZWrite Off
            Cull Back
        
            Tags{"LightMode" = "RednderFront"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD;
                float3 normalOS     : NORMAL;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD;
                float3 positionWS   : TEXCOORD1;
                float3 normalWS     : TEXCOORD2;
                float3 viewWS       : TEXCOORD3;
            };
            
            TEXTURECUBE(_RefractTex);SAMPLER(sampler_RefractTex);
            TEXTURECUBE(_ReflectTex);SAMPLER(sampler_ReflectTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float  _RefractIntensity;
                float  _ReflectIntensity;
                float  _FresnelPower;
                float4 _RimColor;
                float  _RimScale;
                float  _Alpha;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.viewWS = GetWorldSpaceViewDir(o.positionWS);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;

                half3 ambientColor =  _GlossyEnvironmentColor.rgb;

                Light light = GetMainLight(TransformWorldToShadowCoord(i.positionWS));
                half3 lightColor = light.color * light.distanceAttenuation;
                half3 lightDir = light.direction;

                half3 worldViewDir = SafeNormalize(i.viewWS);
                half3 worldNormalDir = normalize(i.normalWS);

                half3 reflectDir = normalize(reflect(-worldViewDir , worldNormalDir));
                half4 refractTex = SAMPLE_TEXTURECUBE_LOD(_RefractTex , sampler_RefractTex , reflectDir , 2);
                half4 reflectTex = SAMPLE_TEXTURECUBE_LOD(_ReflectTex , sampler_ReflectTex , reflectDir , 2);

                half3 refractColor = refractTex.rgb * _Color * _RefractIntensity;
                half3 reflectColor = reflectTex.rgb * _ReflectIntensity;

                //fresnelColor
                half fresnelFactor = max(0.0 , pow((1 - saturate(dot(worldNormalDir , worldViewDir))) , _FresnelPower)) * _RimScale;
                half3 fresnelColor = fresnelFactor * _RimColor;

                half3 TextureColor = refractColor * reflectColor + refractColor;

                FinalColor = half4(TextureColor * fresnelColor +  TextureColor , _Alpha);
                // FinalColor = half4(fresnelColor , 1);

                return FinalColor;
            }
            ENDHLSL  
        }

        //处理物体自身生成阴影..
        Pass
        {
            Name "ShadowCaster"
            Tags {"LightMode" = "ShadowCaster"}

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;       //裁剪空间的维度是四维的
            };

            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings) 0;

                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(v.normalOS);

                //\Library\PackageCache\com.unity.render-pipelines.universal@14.0.8\Editor\ShaderGraph\Includes\Varyings.hlsl
                //获取阴影专用裁剪空间下的坐标
                float4 positionHCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, float3(0,0,0)));
                //判断是否在DirectX平台翻转过坐标
                #if UNITY_REVERSED_Z
                    positionHCS.z = min(positionHCS.z, positionHCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    positionHCS.z = max(positionHCS.z, positionHCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                    o.positionHCS = positionHCS;

                return o;
            }

            half4 frag(Varyings input) : SV_TARGET
            {
                return 0;
            }
            ENDHLSL
        }
    }
}
