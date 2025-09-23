Shader "Shadertoy/Smiley"
{
    Properties
    {
        _LeftPosition("LeftPosition",float) = -0.2
        _RightPosition("RightPosition",float) = 0.2
        _ButtomPosition("ButtomPosition",float) = -0.3
        _TopPosition("TopPosition",float) = 0.3
        _Blur("Blur",float) = 0.01
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" "RenderType" = "Transparent" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attribute
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct Varying
            {
                float2 uv : TEXCOORD0;
                float4 positionHCS : SV_POSITION;
                float2 screenUV : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                float  _LeftPosition;
                float  _RightPosition;
                float  _ButtomPosition;
                float  _TopPosition;
                float  _Blur;
            CBUFFER_END

            float remap01(float a, float b, float t)
            {
                return saturate((t - a)/(b - a));
            }

            float remap(float a , float b, float c ,float d, float t)
            {
                return saturate((t-a)/(b-a) * (d - c)+ c );
            }

            float2 within(float2 uv, float4 rect)
            {
                return (uv - rect.xy)/(rect.zw - rect.xy);
            }

            float4 Eye(float2 uv)
            {
                uv -= 0.5;
                float d = length(uv);
                
                //虹膜颜色
                float4 irisCol = float4(0.3,0.5,1.0, 1.0);
                float4 col = lerp(float4(1.0,1.0,1.0,1.0), irisCol, smoothstep(0.1,0.7,d) * 0.5);
                
                //眼睛阴影
                col.rgb *= 1.0 - smoothstep(0.45, 0.5, d) * 0.5 * saturate(-uv.y - uv.x);
                
                col.rgb = lerp(col.rgb, float3(0.0,0.0,0.0), smoothstep(0.3, 0.28, d));
                
                // 让眼睛中间变量的蓝色渐变衰减
                irisCol.rgb *= 1.0 + smoothstep(0.3, 0.05, d);
                col.rgb = lerp(col.rgb, irisCol.rgb, smoothstep(0.28, 0.25, d));
                //添加瞳孔的黑色区域
                col.rgb = lerp(col.rgb, float3(0.0,0.0,0.0), smoothstep(0.16, 0.14, d));
                
                //添加高光
                float highlight = smoothstep(0.1, 0.09, length(uv - float2(-0.15, 0.15)));
                highlight += smoothstep(0.07, 0.05, length(uv + float2(-0.08, 0.08)));
                col.rgb = lerp(col.rgb, float3(1.0,1.0,1.0), highlight);
                
                col.a = smoothstep(0.5, 0.48, d);
                
                return col;
            }

            float4 Mouth(float2 uv)
            {
                uv -= 0.5;
    
                float4 col = float4(0.5, 0.18, 0.05, 1.0);
                
                //y方向上压扁形状
                uv.y *= 1.5;
                uv.y -= uv.x * uv.x * 2.0;

                float d = length(uv);
                col.a = smoothstep(0.5, 0.48, d);
                
                float td = length(uv - float2(0.0, 0.6));
                float3 toothCol = float3(1.0,1.0,1.0) * smoothstep(0.6, 0.35, d); //牙齿阴影效果，从上到下的衰减渐变
                col.rgb = lerp(col.rgb, toothCol, smoothstep(0.4, 0.37, td));//牙齿
                
                td = length(uv + float2(0.0, 0.5));
                col.rgb = lerp(col.rgb, float3(1.0,0.5,0.5),smoothstep(0.5, 0.2, td));
                
                return col;
            }

            float4 Head(float2 uv)
            {
                float4 col = float4(0.9,0.65,0.1,1.0);
    
                float d = length(uv);
                
                col.a = smoothstep(0.5,0.49,d);
                
                float edgeShade = remap01(0.35, 0.5, d);
                //让黄色圆形从边缘的黑色到中心的白色过渡更平滑
                edgeShade *= edgeShade;
                col.rgb *= 1.0 - edgeShade * 0.5;
                //画边缘的描边线,与原始的颜色进行混合
                col.rgb = lerp(col.rgb, float3(0.6, 0.3, 0.1) , smoothstep(0.47, 0.48, d));
                
                //绘制脸部的高光区域，从上往下的渐变衰减
                float highlight = smoothstep(0.41, 0.405, d);
                highlight *= remap(0.41, -0.1, 0.75, 0.0, uv.y);
                //绘制中间的高亮区域，与上一次计算的颜色进行混合
                col.rgb = lerp(col.rgb, float3(1.0,1.0,1.0), highlight);
                
                //绘制腮红
                d = length(uv - float2(0.25,-0.2));
                float cheek = smoothstep(0.2, 0.01, d) * 0.4;
                //cheek *= S(0.17, 0.16, d);//不加这行代码，晒红的过渡会更顺滑
                col.rgb = lerp(col.rgb, float3(1.0,0.1,0.1), cheek);
                
                return col;
            }

            float4 Smiley(float2 uv)
            {
                float4 col = float4(0.0,0.0,0.0,1.0);
                
                uv.x = abs(uv.x);
                float4 head = Head(uv);
                float4 eye = Eye(within(uv, float4(0.01, -0.1, 0.37, 0.25)));
                float4 mouth = Mouth(within(uv, float4(-0.3, -0.4,0.3,-0.1)));
                
                col = lerp(col, head, head.a);
                col = lerp(col, eye, eye.a);
                col = lerp(col, mouth, mouth.a);
                
                return col;
            }

            Varying vert (Attribute v)
            {
                Varying o=(Varying)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                return o;
            }

            half4 frag (Varying i) : SV_Target
            {
                half4 FinalColor;
                float2 screenUV = i.positionHCS.xy/_ScreenParams.xy;
                screenUV -= 0.5;
                screenUV.x *= _ScreenParams.x/_ScreenParams.y;
             
                FinalColor = Smiley(screenUV);
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
