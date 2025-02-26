//什么是分形？  https://www.zhihu.com/question/265983000/answer/301235097
//https://en.wikipedia.org/wiki/Fractal
//下面shader的效果显示的是Mandblbrot集合
//因为float精度问题，当纹理放大过于大时，会出现像素化的问题，如果一定要处理，可以尝试使用2个float模拟更高的精度

//常见集合：Mandelbrot、Julia、Cantor、Newton、Nova等等

Shader "Art_URP/Base/Effect/Fractal"
{
    Properties
    {
        [NoScaleOffset]_RampMap("RampMap",2D)="white"{}
        _RampMapColor("RampMapColor",color)=(1,1,1,1)
        _InitX("InitX",float)= -0.7452
        _InitY("InitY",float)= 0.186
        _Zoom("Zoom",Range(0.2,1.2)) = 1.2      //放大会失真，导致最终的图像程序像素化
        _Speed("Speed",Range(0,1)) = 0.3
        _MaxIterations("MaxIterations",float) = 256
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry"}

        LOD 100

        pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS     : POSITION;
                float2 texcoord     : TEXCOORD;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD;
            };
            
            TEXTURE2D(_RampMap);SAMPLER(sampler_RampMap);
            CBUFFER_START(UnityPerMaterial)
            float4 _RampMapColor;
            float _InitX;
            float _InitY;
            float _Zoom;
            float _Speed;
            float _MaxIterations;
            CBUFFER_END

            //f(z) = z^2+c
            float2 mandbrot(float2 z , float2 c)
            {
                return float2(z.x*z.x - z.y*z.y , 2.0*z.x*z.y) + c;
            }

            float2 mandelbrotSet(float2 c , int maxIterations)
            {
                float2 z = float2(0,0);
                int i = 0;
                for(;i<maxIterations ; i++)
                {
                    z = mandbrot(z,c);
                    if(z.x*z.x + z.y*z.y > 4.0)
                        break;
                }
                return (float)i/maxIterations;
            }

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.texcoord;

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;

                float2 uv = i.uv + float2(-0.5,-0.5);
                //
                float zoom = pow(0.0015,(1+cos(_Speed * _Time.y + PI)) * 0.5 * _Zoom - 0.2);
                float2 c = float2(_InitX,_InitY) + uv * zoom;
                float iter=mandelbrotSet(c,_MaxIterations);
                FinalColor = SAMPLE_TEXTURE2D(_RampMap,sampler_RampMap,float2(iter,1)) * _RampMapColor;

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
