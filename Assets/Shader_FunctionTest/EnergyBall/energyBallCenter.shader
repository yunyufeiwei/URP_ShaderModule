// 能量球 - 中心
Shader "Art_URP/FunctionTest/energyBallCenter"
{
    // ---------------------------【属性】---------------------------
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("NoiseTex", 2D) = "white" {}
        _Color("Color",Color) = (1,1,1,1)
        _Color1("Color1",Color) = (1,1,1,1)
        _Speed("Speed",Range(-5,5)) = 1
        _Area("Area",Range(0,1)) = 0
        // 光晕相关参数
        [Header(Glow)]
        _GlowRange("GlowRange",Range(0,1)) = 0
        [HDR]_GlowColor("Glow Color", Color) = (1,1,0,1)
        _Strength("Glow Strength", Range(5.0, 1.0)) = 2.0
    }
    // ---------------------------【公共部分】---------------------------
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    struct Attributes
    {
        float4 positionOS   : POSITION;
        float3 normalOS     : NORMAL;
        float2 texcoord     : TEXCOORD0;
    };

    struct v2f_back
    {
        float4 positionHCS : SV_POSITION;
        float4 col : TEXCOORD0;
    };

    struct v2f_front
    {
        float2 uv : TEXCOORD0;
        float4 positionHCS : SV_POSITION;
    };
    
    TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
    TEXTURE2D(_NoiseTex);SAMPLER(sampler_NoiseTex);
    CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float4 _MainTex_TexelSize;
        float4 _NoiseTex_ST;
        float4 _Color;
        float4 _Color1;
        float _Speed;
        float _Area;
        // 光晕相关参数
        float4 _GlowColor;
        float _GlowRange;
        float _Strength;
    CBUFFER_END
    
    //顶点着色器
    v2f_back vert_back(Attributes v)
    {
        v2f_back o;
        // 世界空间下法线和视野方向
        float3 worldNormalDir = mul(v.normalOS, unity_WorldToObject).xyz;
        float3 worldViewDir = _WorldSpaceCameraPos - mul(unity_ObjectToWorld, v.positionOS).xyz;

        //根据法线和视野夹角计算透明度
        float strength = abs(dot(normalize(worldViewDir), normalize(worldNormalDir)));
        float opacity = pow(strength, _Strength);
        o.col = float4(_GlowColor.xyz, opacity);

        // 向法线方向扩张
        float3 pos = v.positionOS.xyz + (v.normalOS * _GlowRange);
        // 转换到裁剪空间
        o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
        return o;
    }

     v2f_front vert_front (Attributes v)
    {
        v2f_front o;
        o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
        o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
        return o;
    }

    //片元着色器
    float4 frag_back(v2f_back i) : COLOR
    {
        return i.col;
    }

    half4 frag_front (v2f_front i) : SV_Target
    {
        float2 uv_offset = float2(0,0);
        float angle = _Time.y * _Speed;
        uv_offset.x = sin(angle);
        uv_offset.y = cos(angle);
        i.uv += uv_offset;
        
        // 获取噪声纹理
        half3 col = SAMPLE_TEXTURE2D(_NoiseTex , sampler_NoiseTex , i.uv).rgb;
        float opacity = step(_Area , col.x);
        half3 result = lerp(_Color.rgb , _Color1.rgb , pow(col.x,1));
        // fixed3 result = smoothstep(_Color,_Color1,(col.x));

        return half4(result.rgb,opacity);
    }
    ENDHLSL

    SubShader
    {
        Tags{"RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Transparent" "RenderType" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        
        // ---------------------------【背面 - 光晕】---------------------------
        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            Cull front
            HLSLPROGRAM
            #pragma vertex vert_back
            #pragma fragment frag_back
            ENDHLSL
        }

        // ---------------------------【正面】---------------------------
        Pass
        {
            Tags{"LightMode" = "SRPDefaultUnlit"}
            ZWrite Off 
            Cull Off
            HLSLPROGRAM
            #pragma vertex vert_front
            #pragma fragment frag_front
            ENDHLSL
        }
    }
}
