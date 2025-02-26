Shader "Art_URP/FunctionTest/ScreenPost/WaterRipple"
{
    Properties
    {
        [PerRendererData]_MainTex ("BaseMap", 2D) = "white" {}
//        _StartPos("StartPos" , Vector) = (0,0,0,0)
//        _waveLength("waveLength",Float) = 92.5
//        _waveHeight("waveHeight",Float) = 0.28
//        _waveWidth("waveWidth",Float) = 0.951
//        _currentWaveDis("currentWaveDis",Float) = 0.187
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" }
        Cull Off
        ZWrite Off
        ZTest Always
        LOD 100

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD;
            };

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _StartPos;
                float  _waveLength;
                float  _waveHeight;
                float  _waveWidth;
                float  _currentWaveDis;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings) 0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionHCS = vertexInput.positionCS;
                
                o.uv = v.texcoord;
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                float2 scale = float2(_ScreenParams.x / _ScreenParams.y , 1);
                float dis = distance(i.uv * scale , _StartPos.xy * scale);

                float offsetX = sin(dis * _waveLength) * _waveHeight * 0.05f;

                //如果该片元不在波纹范围内 偏移设置为0
                if(dis <= _currentWaveDis || dis > _currentWaveDis + _waveWidth){
                    offsetX = 0;
                }
                float2 dv = _StartPos.xy - i.uv;

                i.uv.x += offsetX;
                
                half4 baseMap = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex ,  i.uv);

                FinalColor = baseMap;
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
