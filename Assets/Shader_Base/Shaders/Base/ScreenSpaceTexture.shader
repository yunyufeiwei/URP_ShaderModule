Shader "Art_URP/Base/ScreenSpaceTexture"
{
    Properties
    {
        _BaseMap("BaseMap" , 2D) = "white"{}
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
            
            struct Attributes
            {
                float4 positionOS     : POSITION;
            };
            struct Varyings
            {
                float4 positionHCS    : SV_POSITION;
                float4 screenPosition : TEXCOORD;
            };
            
            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                
                // o.screenPosition = ComputeScreenPos(o.positionHCS);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;

                //这里除以w是因为需要透视除法
                //顶点变换MVP后到齐次裁剪空间(也是顶点着色器的输出) -> 裁剪 ->透视除法除以w分量 -> NDC(标准化设备坐标) -> 屏幕空间;后4步是流水线做的，所以顶点着色器的输出是齐次裁剪空间
                //而我们算的屏幕空间坐标是自己计算的，所以需要自己完成后3步;ComputeScreenPos并没有透视除法（除以w分量），所以得我们自己除w
                //为什么ComputeScreenPos没有在顶点着色器中除以w分量？在片断着色器中除以w分量的目的是为了得到准确的线性插值，因为齐次坐标是非线性数值
                // float2 screenUV = i.screenPosition.xy / i.screenPosition.w;

                //也可是直接使用下面的方法计算屏幕空间uv
                //这里的i.positionHCS.xy刚好等于屏幕上面像素的坐标值，而_ScreenParams.xy表示了屏幕的宽高。
                float2 screenUV = i.positionHCS.xy / _ScreenParams.xy;

                //根据屏幕的宽高比例计算贴图uv比例。不计算aspect也可以，但图片会根据屏幕比例的缩放来拉伸和挤压纹理
                float aspect = _ScreenParams.x / _ScreenParams.y;
                screenUV.x = screenUV.x * aspect;

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap , screenUV);

                FinalColor = baseMap;

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
