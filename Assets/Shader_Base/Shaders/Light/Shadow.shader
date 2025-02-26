Shader "Art_URP/Base/Light/Shadow"
{
    Properties
    {
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}
        LOD 100

        //正常处理物体颜色
        pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //控制模型接受阴影的宏定义
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            //控制模型产生阴影的宏定义
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            //柔化阴影，得到软阴影，如果不添加下面该行，则灯光的softshadow则无效
            #pragma multi_compile _ _SHADOWS_SOFT         
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS     : POSITION;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 positionWS   : TEXCOORD;
            };
            
            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;

                half3 ambientColor = _GlossyEnvironmentColor.xyz;

                Light light = GetMainLight(TransformWorldToShadowCoord(i.positionWS));

                //要保证阴影的效果一直，必须要加上环境光，否则投射在模型上的阴影会死黑，同时计算阴影的时候记得加上灯光衰减(方向光)
                FinalColor = half4(ambientColor + light.color * light.distanceAttenuation * light.shadowAttenuation , 1);
                
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
                float4 positionCS  : SV_POSITION;       //裁剪空间的维度是四维的
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
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, float3(0,0,0)));
                //判断是否在DirectX平台翻转过坐标
                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                    o.positionCS = positionCS;

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
