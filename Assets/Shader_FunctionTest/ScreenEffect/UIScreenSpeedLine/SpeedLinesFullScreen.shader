Shader "Miami/UI/SpeedLinesFullScreen"
{
    Properties
    {
        [HideInInspector][PerRendererData] _MainTex ("MainTex", 2D) = "white" {}

        [Header(Line Settings)]
        _LineColor ("Line Color", Color) = (1, 1, 1, 0.8)
        _GlobalAlpha ("Global Alpha", Range(0, 1)) = 1.0

        [Header(Flow Settings)]
        _FlowSpeed ("Flow Speed Base", Range(0.1, 5.0)) = 1.0
        _LineLength ("Line Length", Range(0.01, 0.5)) = 0.15
        _LineLengthScale ("Line Length Scale", Range(0.1, 3.0)) = 1.0
        _LineThickness ("Line Thickness", Range(0, 1)) = 0.15

        [Header(Shape Settings)]
        _CenterFadeRadius ("Center Fade Radius", Range(0.0, 0.8)) = 0.3

        [HideInInspector] _StencilComp ("Stencil Comparison", Float) = 8
        [HideInInspector] _Stencil ("Stencil ID", Float) = 0
        [HideInInspector] _StencilOp ("Stencil Operation", Float) = 0
        [HideInInspector] _StencilWriteMask ("Stencil Write Mask", Float) = 255
        [HideInInspector] _StencilReadMask ("Stencil Read Mask", Float) = 255
        [HideInInspector] _ColorMask ("Color Mask", Float) = 15
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
            "CanUseSpriteAtlas" = "True"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        ColorMask [_ColorMask]
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Name "SpeedLines"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 texcoord   : TEXCOORD;
                float4 color      : COLOR;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
                float4 color       : COLOR;
            };

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            CBUFFER_START(UnityPerMaterial)
                float4 _LineColor;
                float  _GlobalAlpha;
                float  _FlowSpeed;
                float  _LineLength;
                float  _LineThickness;
                float  _LineLengthScale;
                float  _CenterFadeRadius;
            CBUFFER_END

            // 伪随机哈希函数
            float hash(float n)
            {
                return frac(sin(n) * 43758.5453123);
            }

            // 2D 哈希
            float hash2D(float2 p)
            {
                return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123);
            }

            // 计算单层线条
            // angle: 当前像素相对于中心的角度
            // normDist: 当前像素到中心的归一化距离（0=中心, 1=矩形边缘）
            // numLines: 该层线条数量
            // speed: 流动速度
            // seed: 随机种子偏移
            half computeLineLayer(float angle, float normDist, uint numLines, float speed, float seed)
            {
                half result = 0.0;

                // 将角度映射到 [0, 1] 范围
                float angleFrac = (angle + 3.14159265) / (2.0 * 3.14159265);

                for (uint i = 0; i < numLines; i++)
                {
                    // 每条线的随机角度位置
                    float lineAnglePos = hash(float(i) + seed * 100.0);

                    // 每条线的随机径向偏移和速度变化
                    float lineSpeedVar = 0.7 + hash(float(i) * 1.7 + seed) * 0.6;
                    float lineStartOffset = hash(float(i) * 2.3 + seed);

                    // 计算角度差（环形距离）
                    float angleDiff = abs(angleFrac - lineAnglePos);
                    angleDiff = min(angleDiff, 1.0 - angleDiff);

                    // 角度方向的线条宽度（越远越细的效果）
                    // 将面板 0~1 映射到实际粗细范围 0.0001~0.02
                    float thickness = lerp(0.0001, 0.0006, _LineThickness);
                    float angularWidth = thickness / max(normDist, 0.01);
                    half angularMask = 1.0 - smoothstep(0.0, angularWidth, angleDiff);

                    // 径向方向的流动（从外向内）
                    float flowPos = frac(lineStartOffset + _Time.y * speed * lineSpeedVar);

                    // 线条在径向上的位置（从外向内流动）
                    float lineRadialPos = 1.0 - flowPos;

                    // 径向方向的线条长度遮罩
                    float lineLen = _LineLength * _LineLengthScale;
                    float radialDiff = normDist - lineRadialPos;
                    half radialMask = smoothstep(0.0, lineLen * 0.1, radialDiff)
                                    * (1.0 - smoothstep(lineLen * 0.9, lineLen, radialDiff));

                    // 线条亮度随机变化
                    float brightness = 0.5 + hash(float(i) * 3.1 + seed) * 0.5;

                    result += angularMask * radialMask * brightness;
                }

                return saturate(result);
            }

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.texcoord;
                o.color = v.color;
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                float2 uv = i.positionHCS.xy / _ScreenParams.xy;
                float2 centeredUV = uv - 0.5;

                // 计算极坐标
                float dist = length(centeredUV) * 2.0; // 归一化到 [0, ~1.414]
                float angle = atan2(centeredUV.y, centeredUV.x);

                // 使用矩形边缘距离来归一化dist，确保角落处线条也能到达边缘
                // 计算从中心到当前角度方向上矩形边缘的距离
                float cosA = abs(cos(angle));
                float sinA = abs(sin(angle));
                // 矩形边缘在该方向上的最大距离（UV空间中半宽0.5，半高0.5）
                float maxDist = 1.0 / max(cosA, sinA) * 0.5;
                // 将dist归一化到 [0, 1]，1表示到达矩形边缘
                float normDist = dist / (maxDist * 2.0);

                // 密度等级参数（三挡）
                //uint densityLevel = (uint)round(_LineDensityLevel);
                
                uint numLines = 60u;
                float speed = _FlowSpeed * 1.0;

                // 计算多层线条（不同种子产生不同分布）
                half lineAlpha = 0.0;
                lineAlpha += computeLineLayer(angle, normDist, numLines, speed, 0.0);
                lineAlpha += computeLineLayer(angle, normDist, numLines / 2u, speed * 0.7, 5.0) * 0.5;
                lineAlpha = saturate(lineAlpha);

                half centerFade = smoothstep(_CenterFadeRadius, _CenterFadeRadius + 0.2, normDist);

                half finalMask = centerFade;

                half3 finalColor = _LineColor.rgb;
                half finalAlpha = lineAlpha * finalMask * _LineColor.a * _GlobalAlpha * i.color.a;

                finalColor *= i.color.rgb;

                return half4(finalColor, finalAlpha);
            }
            ENDHLSL
        }
    }
    Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
