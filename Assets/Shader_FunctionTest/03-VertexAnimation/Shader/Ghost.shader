Shader "Art_URP/FunctionTest/Ghost"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GhostColor ("Ghost Color", Color) = (1, 1, 1, 1) //残影颜色
        _Offset ("Offset", Range(0, 2)) = 0 //残影偏离本位的距离
        _GhostAlpha ("Ghost Alpha", Range(0, 1)) = 1 //残影的透明度
        _ShakeLevel ("Shake Level", Range(0, 2)) = 0 //残影抖动的程度
        _ShakeSpeed ("Shake Speed", Range(0, 50)) = 1 //残影的移动速度
        _ShakeDir ("Shake Direction", Vector) = (0, 0, 1, 0) //残影移动的方向
        _Control ("Control", Range(0, 0.54)) = 0 //整体控制残影
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Transparent" "RenderType" = "Transparent" }
        LOD 100

        //渲染本体
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            
            // Required to compile gles 2.0 with standard SRP library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            #pragma vertex vert
            #pragma fragment frag
            
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
            };

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
            CBUFFER_END
            
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                
                return o;
            }
            
            half4 frag(Varyings i): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                return col;
            }
            ENDHLSL
            
        }

        //渲染残影
        Pass
        {
            Tags { "LightMode" = "SRPDefaultUnlit" }            //第二个Pass必须设置为该光照模型
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half4 _GhostColor;
                half _Offset;
                half _GhostAlpha;
                half _ShakeLevel;
                float _ShakeSpeed;
                float4 _ShakeDir;
                half _Control;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                UNITY_SETUP_INSTANCE_ID(v);

                Varyings o = (Varyings)0;
                
                float yOffset = 0.5 * (floor(v.positionOS.x * 10) % 2);
                v.positionOS += _Offset * cos(_Time.y * _ShakeSpeed) * _ShakeDir * _Control;
                v.positionOS += _ShakeLevel * yOffset * sin(_Time.y * _ShakeSpeed) * _ShakeDir * _Control;
                
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                half4 FinalColor;

                half4 mainMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv) * _GhostColor;

                FinalColor =half4(mainMap.rgb , _GhostAlpha);

                return FinalColor;
            }
            ENDHLSL
        }

        
    }
}