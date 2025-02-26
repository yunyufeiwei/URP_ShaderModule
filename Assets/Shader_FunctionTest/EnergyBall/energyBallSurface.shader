// 能量球 - 表面
Shader "Art_URP/FunctionTest/energyBallSurface"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("NoiseTex", 2D) = "white" {}
        _Color("Color",Color) = (1,1,1,1)
        _Speed("Speed",Range(-5,5)) = 1
        _Area("Area",Range(0,1)) = 0
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Transparent" "RenderType" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            ZWrite Off 
            HLSLPROGRAM
            #pragma vertex vert_front
            #pragma fragment frag_front

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 texcoord     : TEXCOORD0;
            };
            
            struct v2f_front
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);SAMPLER(sampler_NoiseTex);
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _MainTex_TexelSize;
                float4 _NoiseTex_ST;
                float4 _Color;
                float _Speed;
                float _Area;
            CBUFFER_END

            v2f_front vert_front (Attributes v)
            {
                v2f_front o;
                o.vertex = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            half4 frag_front (v2f_front i) : SV_Target
            {
                float2 uv_offset = float2(0,0);
                float angle = _Time.y * _Speed;
                uv_offset.x = angle;
                uv_offset.y = angle;
                i.uv += uv_offset;
                // 获取噪声纹理
                half3 col = SAMPLE_TEXTURE2D(_NoiseTex , sampler_NoiseTex , i.uv).rgb;
                float opacity = step(_Area,col.x);

                return half4(_Color.rgb,opacity);
            }
            ENDHLSL
        }
    }
}
