Shader "Art_URP/FunctionTest/screenEffect/gaussBlur"  
{  
    Properties  
    {  
        _MainTex("MainTex", 2D) = "white" {} 
        _offsets("offsets" , Vector) = (0,0,0,0) 
    }  
    SubShader  
    {  
        Tags {"RenderPipeline" = "UniversalRenderPipeline" "Queue"="Transparent" "RenderType"="Transparent"}
        ZTest Always  
        Cull Off  
        ZWrite Off  
        Fog{ Mode Off }  
        
        Pass  
        {  
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM  
            #pragma vertex vert_blur  
            #pragma fragment frag_blur
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
            };
            
            //顶点着色器输出结构体 
            struct Varyings  
            {  
                float4 positionHCS : SV_POSITION;   //顶点位置  
                float2 uv  : TEXCOORD0;     //纹理坐标  
                float4 uv01 : TEXCOORD1;    //存储两个纹理坐标  
                float4 uv23 : TEXCOORD2;    //存储两个纹理坐标  
            };

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_TexelSize;       //纹理中的单像素尺寸  
                float4 _offsets;               //给一个offset，这个offset可以在外面设置，是我们设置横向和竖向blur的关键参数  
            CBUFFER_END
            
            Varyings vert_blur(Attributes v)  
            {  
                Varyings o = (Varyings)0;  
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);  
                o.uv = v.texcoord.xy;  
                
                //计算一个偏移值
                // offset（1，0，0，0）代表水平方向
                // offset（0，1，0，0）表示垂直方向  
                _offsets *= _MainTex_TexelSize.xyxy;  
                
                //由于uv可以存储4个值，所以一个uv保存两个vector坐标，_offsets.xyxy * float4(1,1,-1,-1)可能表示(0,1,0-1)，表示像素上下两个  
                //坐标，也可能是(1,0,-1,0)，表示像素左右两个像素点的坐标，下面*2.0，同理
                o.uv01 = v.texcoord.xyxy + _offsets.xyxy * float4(1, 1, -1, -1);  
                o.uv23 = v.texcoord.xyxy + _offsets.xyxy * float4(1, 1, -1, -1) * 2.0;  
                
                return o;  
            }  

            // 计算高斯权重
            float computerBluGauss(float x,float sigma) {
                return 0.39894*exp(-0.5*x*x/(0.20*sigma))/sigma*sigma;
            }
            
            half4 frag_blur(Varyings i) : SV_Target  
            {  
                half4 color = half4(0,0,0,0);  
                //将像素本身以及像素左右（或者上下，取决于vertex shader传进来的uv坐标）像素值的加权平均  
                
                //这里的权值由高斯公式计算而来:
                // y = 0.39894*exp(-0.5*x*x/(sigma*sigma))/sigma;  sigma = 7;
                // 例如:
                // float w0 = computerBluGauss(0,8);
                // float w1 = computerBluGauss(1,8);
                // float w2 = computerBluGauss(2,8);
                // float sum = w0+w1*2+w2*2;
                // color += w0/sum * tex2D(_MainTex, i.uv);  
                // color += w1/sum * tex2D(_MainTex, i.uv01.xy);  
                // color += w1/sum * tex2D(_MainTex, i.uv01.zw);  
                // color += w2/sum * tex2D(_MainTex, i.uv23.xy);  
                // color += w2/sum * tex2D(_MainTex, i.uv23.zw);  

                //为了节约性能, 这里就直接取计算后的权值
                color += 0.4026 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv);  
                color += 0.2442 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv01.xy);
                color += 0.2442 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv01.zw);  
                color += 0.0545 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv23.xy);  
                color += 0.0545 * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv23.zw);  
                return color;
                // return fixed4(1,0,0,1);
            }
            ENDHLSL
        }  
    }  
}  