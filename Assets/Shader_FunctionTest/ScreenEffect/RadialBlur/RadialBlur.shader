Shader "Art_URP/FunctionTest/screenEffect/RadialBlur"
{
    Properties 
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _BlurFactor("_BlurFactor", Float) = 0
        _BlurCenter("_BlurCenter" , Vector) = (0,0,0,0)
        [IntRange]_IterationCount("InterationCount" , Range(0,10)) = 5
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
            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_fastest 

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
                uniform float _BlurFactor;	//模糊强度
                uniform float2 _BlurCenter; //模糊中心点
                uniform float _IterationCount;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;  
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);  
                o.uv = v.texcoord.xy;

                return o;
            }
            
            half4 frag(Varyings i) : SV_Target
            {
                float4 FinalColor = 0;
                //模糊方向: 中心像素 - 当前像素
                float2 dir = (_BlurCenter.xy - i.uv ) * _BlurFactor * 0.01;
                
                //迭代
                for (int j = 0; j < _IterationCount; ++j)
                {
                    //计算采样uv值：正常uv值+从中间向边缘逐渐增加的采样距离
                    float2 uv = i.uv + dir * j;
                    FinalColor += SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , uv);
                }
                //取平均值(乘法比除法性能好)
                FinalColor /= _IterationCount;
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
