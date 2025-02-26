Shader "Art_URP/FunctionTest/PerlinNoiseMirror" 
{
    Properties 
    {
        [NoScaleOffset] _MainTex ("MainTex", 2D) = "white" {}               // 主纹理
        [NoScaleOffset] _NoiseTex ("NoiseTex", 2D) = "white" {}             // 噪点图
        _NoiseScaleX ("NoiseScaleX", Range(0, 1)) = 0.1                     // 水平噪点放大系数
        _NoiseScaleY ("NoiseScaleY", Range(0, 1)) = 0.1                     // 垂直放大系数
        _NoiseSpeedX ("NoiseSpeedX", Range(0, 10)) = 1                      // 水平扰动速度
        _NoiseSpeedY ("NoiseSpeedY", Range(0, 10)) = 1                      // 垂直扰动速度
        _NoiseBrightOffset ("NoiseBrightOffset", Range(0, 0.9)) = 0.25      // 噪点图整体的数值偏移
        _NoiseFalloff ("NoiseFalloff", Range(0, 1)) = 1                     // 扰动衰减

        _MirrorRange ("MirrorRange", Range(0, 3)) = 1                       // 镜面范围（最大范围，超出该范围就不反射）
        _MirrorAlpha ("MirrorAlpha", Range(0, 1)) = 1                       // 镜面图像不透明度
        _MirrorFadeAlpha ("_MirrorFadeAlpha", Range(0,1)) = 0.5             // 镜面范围值边缘位置的不透明度，如果调整为0，意思越接近该最大范围的透明就越接近该值：0
    }
    
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

    struct Attributes
    {
        float4 positionOS   : POSITION;
        float3 normalOS   : NORMAL;
        float2 texcoord : TEXCOORD0;
    };

    struct v2f
    {
        float4 positionHCS  : SV_POSITION;
        float2 uv           : TEXCOORD0;
        float3 positionWS   : TEXCOORD1;
    };

    struct v2f_m
    {
        float4 positionHCS : SV_POSITION;
        float2 uv : TEXCOORD0;
        float4 normalWS : TEXCOORD1;
        float4 positionWS : TEXCOORD2;
    };

    TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
    TEXTURE2D(_NoiseTex);SAMPLER(sampler_NoiseTex);
    CBUFFER_START(UnityPerMaterial)
        half _NoiseScaleX, _NoiseScaleY;
        half _NoiseSpeedX, _NoiseSpeedY;
        half _NoiseBrightOffset;
        half _NoiseFalloff;
        float _MirrorRange, _MirrorAlpha, _MirrorFadeAlpha;
        float3 n, p; // 镜面法线，镜面任意点
    CBUFFER_END
    
    v2f vert_normal (Attributes v)
    {
        v2f o;
        o.positionWS = mul(unity_ObjectToWorld, v.positionOS).xyz;
        o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
        o.uv = v.texcoord;
        return o;
    }
    
    half4 frag_normal (v2f i) : SV_Target
    {
        float3 dir = i.positionWS.xyz - p;                // 平面与插值点的指向
        half d = dot(dir, n);                       // 与反向镜面的距离
        if (d < 0) discard;                         // 如果平面背面，那就丢弃

        return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv);
    }
    
    v2f_m vert_mirror (Attributes v)
    {
        v2f_m o;

        o.positionWS = mul(unity_ObjectToWorld, v.positionOS);

        float3 nn = -n;                 // 法线反向
        float3 dp = o.positionWS.xyz - p;     // 平面点与世界空间的点的向量（即：从平面的点指向世界空间点的方向）
        half nd = dot(n, dp);           // 计算出点与平面的垂直距离
        o.positionWS.xyz += nn * (nd * 2);    // 将垂直距离反向2倍的距离，就是镜像的位置
        
        o.positionHCS = mul(unity_MatrixVP, o.positionWS);
        o.normalWS.xyz = TransformObjectToHClip(v.normalOS);

        half t = nd / _MirrorRange;       // 将位置与镜面最大范围比利作为fade alpha的插值系数
        half a = lerp(_MirrorAlpha, _MirrorAlpha * _MirrorFadeAlpha, t);
        o.normalWS.w = a;     // 透明度我们存于o.normal.w
        o.positionWS.w = nd;      // 距离存于o.wPos.w
        o.uv = v.texcoord;
        
        return o;
    }
    
    half4 frag_mirror (v2f_m i) : SV_Target
    {
        if (i.positionWS.w > _MirrorRange) discard;       // 超过镜像范围也丢弃
        if (i.normalWS.w <= 0) discard;               // 透明度为0丢弃

        float3 dir = i.positionWS.xyz - p;                // 平面与插值点的指向
        half d = dot(dir, n);                       // 与反向镜面的距离
        if (d > 0) discard;                         // 如果超过了平面，那就丢弃

        half2 ouvxy = half2( // 噪点图采样，用于主纹理的UV偏移的
            SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex , i.uv + half2(_Time.x * _NoiseSpeedX, 0)).r,
            SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex , i.uv + half2(0, _Time.x * _NoiseSpeedY)).r);
            
        ouvxy -= _NoiseBrightOffset; // 0~1 to ==> -_NoiseBrightOffset~ 1 - _NoiseBrightOffset
        ouvxy *= half2(_NoiseScaleX, _NoiseScaleY);    // 扰动放大系数
        
        float scale = i.positionWS.w / _MirrorRange;          // 用距离来作为扰动衰减
        scale = lerp(scale, 1, (1 - _NoiseFalloff));    // 距离越近扰动越是衰减（即：与镜面距离越近，基本是不扰动的，所以我们可以看到边缘与镜面的像素是吻合的）
        ouvxy *= scale;
        
        half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv + ouvxy);     // 加上扰动UV后再采样主纹理
        return half4(col.rgb, i.normalWS.w);
    }
    ENDHLSL

    SubShader 
    {
        Tags {"RenderPipeline" = "UniversalRenderPipeline" "Queue"="Geometry+2" "RenderType"="Opaque" }
        Pass 
        {
            Tags{"LightMode" = "UniversalForward"}
            
            HLSLPROGRAM
            #pragma vertex vert_normal
            #pragma fragment frag_normal
            ENDHLSL
        }
        Pass 
        {
            Tags{"LightMode" = "SRPDefaultUnlit"}
            Cull front
            ZTest Always
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Stencil 
            {
                Ref 1
                Comp Equal
            }
            HLSLPROGRAM
            #pragma vertex vert_mirror
            #pragma fragment frag_mirror
            ENDHLSL
        }

        
    }
}
