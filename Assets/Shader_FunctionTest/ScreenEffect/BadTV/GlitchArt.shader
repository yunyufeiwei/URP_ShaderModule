/*
* @Descripttion: 故障艺术（故障艺术（坏电视））特效
* @Author: lichanglong
* @Date: 2020-12-18 18:06:05
 * @FilePath: \LearnUnityShader\Assets\Scenes\ScreenEffect\BadTV\GlitchArt.shader
*/
// ---------------------------【故障艺术（坏电视）特效】---------------------------

Shader "Art_URP/FunctionTest/screenEffect/GlitchArt"
{
    // ---------------------------【属性】---------------------------
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ScanLineJitter("_ScanLineJitter" , vector ) = (0,0,0,0)
        _VerticalJump("_VerticalJump" , Vector) = (0,0,0,0)
        _HorizontalShake("_HorizontalShake",Float) = 0
        _ColorDrift("_ColorDrift" , Vector) = (0,0,0,0)
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    struct Attributes
    {
        float4 positionOS   : POSITION;
        float2 texcoord     : TEXCOORD0;
    };
    struct Varyings
    {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
    };

    TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
    CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        float2 _MainTex_TexelSize;
        float2 _ScanLineJitter; // (displacement, threshold)
        float2 _VerticalJump;   // (amount, time)
        float _HorizontalShake;
        float2 _ColorDrift;     // (amount, time)
    CBUFFER_END

    float nrand(float x, float y)
    {
        return frac(sin(dot(float2(x, y), float2(12.9898, 78.233))) * 43758.5453);
    }

    Varyings vert(Attributes v)
    {
        Varyings o = (Varyings)0;
        o.pos = TransformObjectToHClip(v.positionOS.xyz);
        o.uv = v.texcoord;
        return o;
    }
    
    half4 frag(Varyings i) : SV_Target
    {
        float u = i.uv.x;
        float v = i.uv.y;

        // Scan line jitter
        float jitter = nrand(v, _Time.x) * 2 - 1;
        jitter *= step(_ScanLineJitter.y, abs(jitter)) * _ScanLineJitter.x;

        // Vertical jump
        float jump = lerp(v, frac(v + _VerticalJump.y), _VerticalJump.x);

        // Horizontal shake
        float shake = (nrand(_Time.x, 2) - 0.5) * _HorizontalShake;

        // Color drift
        float drift = sin(jump + _ColorDrift.y) * _ColorDrift.x;

        half4 src1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , frac(float2(u + jitter + shake, jump)));
        half4 src2 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , frac(float2(u + jitter + shake + drift, jump)));

        return half4(src1.r, src2.g, src1.b, 1);
    }
    
    ENDHLSL

    // ---------------------------【子着色器】---------------------------
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalRenderPipeline" "Queue"="Transparent" "RenderType"="Transparent"}
        
        // ---------------------------【渲染通道】---------------------------
        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            ZTest Always Cull Off ZWrite Off
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            ENDHLSL
        }
    }
}
