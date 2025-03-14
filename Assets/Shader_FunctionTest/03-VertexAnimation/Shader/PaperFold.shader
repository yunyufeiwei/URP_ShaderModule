Shader "Art_URP/FunctionTest/Ghost"
{
    Properties
    {
        _FrontTex ("Front Tex", 2D) = "white" { }
        _BackTex("Back Tex",2D) = "white" {}
        _FoldPos("Fold Pos",Float) = 0.0
        _FoldAngle("Fold Angle",Range(1,180)) = 90
        [Toggle(ENABLE_DOUBLE)]_DoubleFold("Double Fold",Float) = 0
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Transparent" "RenderType" = "Transparent" }
        LOD 100

        //正面剔除
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            ZWrite On
            Cull Front
            Blend SrcAlpha OneMinusSrcAlpha
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma shader_feature ENABLE_DOUBLE
            
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
            };

            TEXTURE2D(_BackTex);    SAMPLER(sampler_BackTex);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BackTex_ST;
                float _FoldPos;
                float _FoldAngle;
            CBUFFER_END
            
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                float angle = _FoldAngle;
                float r = _FoldPos - v.positionOS.x;
                #if ENABLE_DOUBLE
                    if (r < 0) 
                    {
                        angle = 360 - _FoldAngle;
                    }
                #else
                    if (r < 0) 
                    {
                        angle = 180;
                    }
                #endif
                
                v.positionOS.x = _FoldPos + r * cos(angle * PI / 180);
                v.positionOS.y  = r * sin(angle * PI / 180);

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord,_BackTex);
                
                return o;
            }
            
            half4 frag(Varyings i): SV_Target
            {
                half4 FinalColor;
                

                half4 mainMap = SAMPLE_TEXTURE2D(_BackTex, sampler_BackTex, i.uv);

                FinalColor = mainMap;
                return FinalColor;
            }
            ENDHLSL
            
        }

        //背面剔除
        Pass
        {
            Tags { "LightMode" = "SRPDefaultUnlit" }

            ZWrite On
            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha
            
            HLSLPROGRAM
            
            // Required to compile gles 2.0 with standard SRP library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma shader_feature ENABLE_DOUBLE
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            #pragma vertex vert
            #pragma fragment frag
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 _FrontTex_ST;
                float  _FoldPos;
                float  _FoldAngle;
            CBUFFER_END
            
            TEXTURE2D(_FrontTex);    SAMPLER(sampler_FrontTex);
            
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                float angle = _FoldAngle;
                float r = _FoldPos - v.positionOS.x;

                #if ENABLE_DOUBLE
                    if (r < 0) 
                    {
                        angle = 360 - _FoldAngle;
                    }
                #else
                    if (r < 0) 
                    {
                        angle = 180;
                    }
                #endif

                v.positionOS.x = _FoldPos + r * cos(angle * PI / 180);
                v.positionOS.y  = r * sin(angle * PI / 180);

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord,_FrontTex);
                
                return o;
            }
            
            half4 frag(Varyings i): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                half4 col = SAMPLE_TEXTURE2D(_FrontTex, sampler_FrontTex, i.uv);
                return col;
            }
            ENDHLSL
        }

        
    }
}