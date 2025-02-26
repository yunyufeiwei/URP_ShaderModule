Shader "Art_URP/FunctionTest/DirectionAsh"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset]_NoiseTex ("Noise Tex", 2D) = "white" { }
        [NoScaleOffset]_WhiteNoiseTex("White Noise Tex",2D) = "white" {}
        [NoScaleOffset]_RampTex ("Ramp Tex", 2D) = "white" { }
        _Threshold ("Threshold", Range(0, 1)) = 0
        _EdgeLength ("Edge Length", Range(0.0, 0.2)) = 0.1

        _MinBorderY("Min Border Y",Float) = 0
        _MaxBorderY("Max Border Y",Float) = 0
        _DistanceEffect ("Distance Effect", Range(0, 1)) = 0.5
        _AshColor("Ash Color",Color) = (1,1,1,1)
        _AshWidth("Ash Width",range(0.0,0.25)) = 0
        _AshDensity("Ash Density", Range(0, 1)) = 1
        _FlyIntensity("Fly Intensity", Range(0,0.3)) = 0.1  //灰尘移动的强度
		_FlyDirection("Fly Direction", Vector) = (1,1,1,1)  //灰尘移动方向
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        LOD 100

        Pass
        {
            Tags{"RenderPipeline" = "UniversalPipeline"}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma vertex vert
            #pragma fragment frag

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 positionWS   : TEXCOORD1;
            };

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);   SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_WhiteNoiseTex);SAMPLER(sampler_WhiteNoiseTex);
            TEXTURE2D(_RampTex);   SAMPLER(sampler_RampTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float  _Threshold;
                float  _EdgeLength;
                float  _MinBorderY;
                float  _MaxBorderY;
                float  _DistanceEffect;
                float4 _AshColor;
                float  _AshWidth;
                float  _AshDensity;
                float  _FlyIntensity;
                float4 _FlyDirection;
            CBUFFER_END

            float GetNormalizedDistance(float posY)
            {
                float range = _MaxBorderY - _MinBorderY;
                float border = _MaxBorderY;

                float distance = abs(posY - border);
                return saturate(distance / range);
            }

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);

                float cutout = GetNormalizedDistance(o.positionWS.y);
                //操作顶点进行偏移
                float3 localFlyDirection = TransformWorldToObjectDir(_FlyDirection.xyz);    
                float flyDegree = (_Threshold- cutout) / _EdgeLength;
                float val = saturate(flyDegree * _FlyIntensity);
                v.positionOS.xyz += localFlyDirection * val;

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                half4 FinalColor;

                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv);
                half  noiseMap = SAMPLE_TEXTURE2D(_NoiseTex , sampler_NoiseTex , i.uv).r;
                half  whiteNoiseMap = SAMPLE_TEXTURE2D(_WhiteNoiseTex , sampler_WhiteNoiseTex , i.uv).r;

                half  normalizedDistance = GetNormalizedDistance(i.positionWS.y);

                float cutout = noiseMap * (1.0 - _DistanceEffect) + normalizedDistance * _DistanceEffect;
                float edgeCutout = cutout - _Threshold;
                clip(edgeCutout + _AshWidth);
                
                float degree = saturate(edgeCutout / _EdgeLength);
                half4 edgeColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(degree, degree));
                
                FinalColor = lerp(edgeColor, mainTex, degree);
                if(degree < 0.001)
                {
                    clip(whiteNoiseMap * _AshDensity + normalizedDistance * _DistanceEffect - _Threshold);
                    FinalColor = _AshColor;
                }

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
