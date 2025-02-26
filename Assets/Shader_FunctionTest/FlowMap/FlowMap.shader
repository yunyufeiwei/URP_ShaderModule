Shader "Art_URP/FunctionTest/FlowMap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _FlowMap ("Flow Map", 2D) = "white" { }
        _Tilling ("Tilling", Range(0, 10)) = 1
        _Speed ("Speed", Range(0, 100)) = 10
        _Strength ("Strength", Range(0, 10)) = 1
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/ShaderLibs/Node.hlsl"
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            TEXTURE2D(_FlowMap);SAMPLER(sampler_FlowMap);
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            CBUFFER_START(UnityPerMaterial)
                float4 _FlowMap_ST;
                float4 _MainTex_ST;
                float _Speed;
                float _Strength;
                float _Tilling;
            CBUFFER_END
            
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.vertex = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord, _FlowMap);
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                // half speed = _Time.x * _Speed;
                // half speed1 = frac(speed);
                // half speed2 = frac(speed + 0.5);
                //
                // half4 flow = SAMPLE_TEXTURE2D(_FlowMap , sampler_FlowMap , i.uv);
                // half2 flow_uv = - (flow.xy * 2 - 1);
                //
                // half2 flow_uv1 = flow_uv * speed1 * _Strength;
                // half2 flow_uv2 = flow_uv * speed2 * _Strength;
                //
                // flow_uv1 += (i.uv * _Tilling);
                // flow_uv2 += (i.uv * _Tilling);
                //
                // half4 col = SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , flow_uv1);
                // half4 col2 = SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , flow_uv2);
                //
                // float lerpValue = abs(speed1 * 2 - 1);
                // half4 finalCol = lerp(col, col2, lerpValue);

                //使用封装的函数来输出表现效果
                half4 finalCol = FlowMapNode(_MainTex , sampler_MainTex , _FlowMap , sampler_FlowMap , i.uv, _Tilling, _Speed, _Strength);
                return finalCol;
            }
            ENDHLSL
        }
    }
}
