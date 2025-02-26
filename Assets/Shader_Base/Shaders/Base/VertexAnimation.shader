Shader "Art_URP/Base/VertexAnimation"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _MaxHeight("MaxHeight",float) = 1.0
        _Speed("Speed",float) = 1.0
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque"  "Queue" = "Geometry"}

        LOD 100

        pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct Attributes
            {
                float4 positionOS     : POSITION;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 positionWS   : TEXCOORD;
            };
            
            //CBuffer部分，数据参数定义在该结构内，可以使用srp的batch功能
            CBUFFER_START(UnityPerMaterial)
            float4 _Color;
            float  _MaxHeight;
            float  _Speed;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                float3 offsetPos = o.positionWS;
                offsetPos += abs(sin(_Time.y * _Speed) * float3(0,_MaxHeight,0));
                
                //这里容易出错，在空间变化中，需要将模型顶点最终转换到齐次裁剪空间，但顶点动画的顶点在裁剪之前从模型空间转换到了世界空间，因此这里要用TransformWorldToHClip()方法
                //即使用世界空间到齐次裁剪空间的变换矩阵
                o.positionHCS = TransformWorldToHClip(offsetPos.xyz);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;

                FinalColor =  _Color;

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
