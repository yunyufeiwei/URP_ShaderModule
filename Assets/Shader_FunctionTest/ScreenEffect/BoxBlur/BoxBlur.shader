Shader "Art_URP/FunctionTest/screenEffect/BoxBlur"  
{  
    Properties  
    {  
        _MainTex("MainTex", 2D) = "white" {}  
        _BlurRadius("_BlurRadius" , Float) = 0
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
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

             struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
            };
            
            struct Varyings  
            {  
                float4 positionHCS  : SV_POSITION;   //顶点位置  
                float2 uv           : TEXCOORD0;    //纹理坐标
                float4 uv1          : TEXCOORD1;    //存储两个uv坐标
                float4 uv2          : TEXCOORD2;    //存储两个uv坐标
                float4 uv3          : TEXCOORD3;    //存储两个uv坐标
                float4 uv4          : TEXCOORD4;    //存储两个uv坐标
            };  

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_TexelSize;
                float _BlurRadius;
            CBUFFER_END
            
            Varyings vert(Attributes v)  
            {  
                Varyings o = (Varyings)0;  
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);  
                //uv坐标  
                o.uv = v.texcoord.xy;  
                //计算周围的8个uv坐标
                o.uv1.xy = v.texcoord.xy + _MainTex_TexelSize.xy * float2(1, 0) * _BlurRadius;  
                o.uv1.zw = v.texcoord.xy + _MainTex_TexelSize.xy * float2(-1, 0) * _BlurRadius;

                o.uv2.xy = v.texcoord.xy + _MainTex_TexelSize.xy * float2(0, 1) * _BlurRadius;
                o.uv2.zw = v.texcoord.xy + _MainTex_TexelSize.xy * float2(0, -1) * _BlurRadius;

                o.uv3.xy = v.texcoord.xy + _MainTex_TexelSize.xy * float2(1, 1) * _BlurRadius;
                o.uv3.zw = v.texcoord.xy + _MainTex_TexelSize.xy * float2(-1, 1) * _BlurRadius;

                o.uv4.xy = v.texcoord.xy + _MainTex_TexelSize.xy * float2(1, -1) * _BlurRadius;
                o.uv4.zw = v.texcoord.xy + _MainTex_TexelSize.xy * float2(-1, -1) * _BlurRadius;
                return o;  
            }  
            
            half4 frag(Varyings i) : SV_Target  
            {  
                half4 color = half4(0,0,0,0);
                
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv.xy);
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv1.xy);
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv1.zw);
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv2.xy);
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv2.zw);
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv3.xy);
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv3.zw);
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv4.xy);
                color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv4.zw);
                
                // 取平均值
                return color / 9;
            }
            ENDHLSL
        }  
    }  
}  