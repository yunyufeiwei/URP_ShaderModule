Shader "Art_URP/FunctionTest/VertexPropertyShow"
{
    Properties
    {
        [Toggle(_COLORSHOWOBJECTSPACE_ON)]_VertexShowColorShow("ColorShowObjectSpace",int) = 0
        [Toggle(_COLORSHOWWORLDSPACE_ON)]_ColorShowWorldSpace("ColorShowWorldSpace",int) = 0
        [Toggle(_UVCOLORSHOW_ON)]_UVColorShow("UVColorShow",int) = 0
        [Toggle(_NORMALCOLORSHOW_ON)]_NormalColorShow("NormalColorShow",int) = 0

        _Color("Color",Color)=(1,1,1,1)
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" }

        LOD 100

        pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma shader_feature _COLORSHOWOBJECTSPACE_ON
            #pragma shader_feature _COLORSHOWWORLDSPACE_ON
            #pragma shader_feature _UVCOLORSHOW_ON
            #pragma shader_feature _NORMALCOLORSHOW_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD;
                float3 normalOS     : NORMAL;
                float4 color        : COLOR;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD;
                float3 positionOS   : TEXCOORD1;
                float3 positionWS   : TEXCOORD2;
                float3 normalLoc    : TEXCOORD3;
                float4 color        : COLOR;
            };

            //CBuffer部分，数据参数定义在该结构内，可以使用srp的batch功能
            CBUFFER_START(UnityPerMaterial)
                int _VertexColorShow;
                int _UVColorShow;
                int _NormalColorShow;
                int _VertexColorWS;

                float4 _Color;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                //将模型的顶点位置输出到裁剪空间
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                //模型的顶点在本地空间输出
                o.positionOS = v.positionOS.xyz;
                //模型的顶点在世界空间输出
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.uv = v.texcoord;
                o.normalLoc = v.normalOS;
                o.color = v.color;

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor = i.color;

                //输出模型本地空间的颜色
                #if _COLORSHOWOBJECTSPACE_ON
                    half3 vertexColorOS = i.positionOS;
                    FinalColor = half4(vertexColorOS,1);
                #endif

                #if _COLORSHOWWORLDSPACE_ON
                    half3 vertexColorWS = i.positionWS;
                    FinalColor = half4(vertexColorWS,1);
                #endif

                #if _UVCOLORSHOW_ON
                    half2 UVColor = i.uv;
                    FinalColor = half4(UVColor , 0 , 1);
                #endif

                #if _NORMALCOLORSHOW_ON
                    half3 normalColor = i.normalLoc;
                    FinalColor = half4(normalColor,1);
                #endif

                return FinalColor;
            }
            ENDHLSL  
        }
        //投射阴影
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

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
                float4 positionCS   : SV_POSITION;
            };


            Varyings vert(Attributes input)
            {
                Varyings output;
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, float3(0,0,0)));
                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                output.positionCS = positionCS;
                return output;
            }

            half4 frag(Varyings input) : SV_TARGET
            {
                return 0;
            }
            ENDHLSL
        }
    }
}
