//Z-Bias渲染背面而不是渲染正面，然后观察空间下物体的顶点的Z值沿着相机方向移动一点距离，也就是更靠近摄像机，使得边缘凸出
//该方式等于是又将物体画了一遍，所以我们有2个Pass，第1个Pass正常画，第2个Pass是轮廓
//想要2个Pass，简单的办法就是在RendererDeature上加一个LightMode Tags，注意看主摄像机的Renderer是CartoonRenderer,在该物体下加了个Render Objects并添加了一个叫Outline的LightMode
//因此第二个Pass叫做Outline   ---Tags{"LightMode" = "Outline"}

//弊端：当描边过粗时，该效果不好，你会看到多出来一个物体，毕竟只是再画一遍然后偏移


//https://zhuanlan.zhihu.com/p/129291888
//https://zhuanlan.zhihu.com/p/26409746

//配置方式：
//---首先需要在Unity中创建一个Universal Renderer Data，并在其中添加Render Object(Experimental)，在下面的LightMode中添加shader内定义的Pass
//---齐次，需要在项目设置的渲染管线组件的Renderer List中添加自定义的Universal Renderer Data数据配置

Shader "Art_URP/Base/NPR/OutLine Z-Bais"
{
    Properties
    {
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _ZBias ("Outline Width (ZBias)",Float) = 0.5
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}
        LOD 100
        //绘制正面
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
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 normalWS     : TEXCOORD1;
                float3 viewWS       : TEXCOORD2;
            };
            
            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;

                FinalColor = half4(1.0,1.0,1.0,1.0);

                return FinalColor;
            }
            ENDHLSL  
        }

        //背面绘制
        pass
        {
            //Tags{"LightMode" = "Outline1"}
            Tags{"LightMode" = "SRPDefaultUnlit"}

            Cull Front

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _OutlineColor;
            float  _ZBias;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                //转换到观察空间
                half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                half3 positionVS = TransformWorldToView(positionWS);

                positionVS.z += _ZBias;

                o.positionHCS = TransformWViewToHClip(positionVS);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;

                FinalColor = _OutlineColor;

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
