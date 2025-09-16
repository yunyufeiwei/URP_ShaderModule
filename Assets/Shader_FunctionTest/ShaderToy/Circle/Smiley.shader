Shader "Unlit/NewUnlitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Size("Size",Float) = 1.0
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" "RenderType" = "Transparent" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attribute
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct Varying
            {
                float2 uv : TEXCOORD0;
                float4 positionHCS : SV_POSITION;
                float2 screenUV : TEXCOORD1;
            };

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float  _Size;
            CBUFFER_END

            float Circle(float2 uv, float2 position, float radiu, float blur)
            {
                float distance = length(uv-position);
                float colMask = smoothstep(radiu,radiu-blur,distance);
                return colMask;
            }

            float Smiley(float2 uv, float2 position, float size)
            {
                uv -= position;
                uv /= size;

                float mask = Circle(uv,float2(0.0,0.0),0.4,0.01);
                mask -= Circle(uv,float2(-0.13,0.2),0.07,0.01);
                mask -= Circle(uv,float2(0.13,0.2),0.07,0.01);

                float mouth = Circle(uv,float2(0.0,0.0),0.3,0.02);
                mouth-= Circle(uv,float2(0.0,0.1),0.3,0.02);

                mask -= mouth * mask;
                return mask;
            }

            Varying vert (Attribute v)
            {
                Varying o=(Varying)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                //o.screenUV = ComputeScreenPos(o.positionHCS);
                return o;
            }

            half4 frag (Varying i) : SV_Target
            {
                half4 FinalColor;
                float2 screenUV = i.positionHCS.xy/_ScreenParams.xy;
                // float2 screenUV = ComputeScreenPos(i.positionHCS).xy /_ScreenParams.xy;
                screenUV.y = 1- screenUV.y;
                screenUV -= 0.5;
                screenUV.x *= _ScreenParams.x/_ScreenParams.y;
                
                // return half4(screenUV,0.0,1.0);

                // float distance = length(screenUV);
                // float colMask = smoothstep(0.2,0.3,distance);
                // float d = length(screenUV);
                //
                // float mask = Circle(screenUV,float2(0.0,0.0),0.4,0.01);
                // mask -= Circle(screenUV,float2(-0.13,0.2),0.07,0.01);
                // mask -= Circle(screenUV,float2(0.13,0.2),0.07,0.01);
                //
                // float mouth = Circle(screenUV,float2(0.0,0.0),0.3,0.02);
                // mouth -= Circle(screenUV,float2(0.0,0.1),0.3,0.02);
                //
                // mouth = mouth * mask;
                // mask -= mouth;

                float mask = Smiley(screenUV,float2(0.0,0.0),_Size);

                FinalColor = half4(mask.xxx,1.0);
                
                
                return mask;
            }
            ENDHLSL
        }
    }
}
