Shader "Art_URP/FunctionTest/InstancedShader"
{
    Properties
    {
        _Color("Color" , Color) = (1,1,1,1)
        _BaseMap ("BaseMap", 2D) = "white" {}
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma target 4.5  //需要定义编译目标的级别，否则该Shader会走else部分，即编译目标级别低于4.5
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            //这个功能最低支持的编译目标级别为4.5，即OpenGL ES 3.1
            #if SHADER_TARGET >= 45
                StructuredBuffer<float4> positionBuffer;
            #endif
            
            struct Attributes
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 positionOS   : POSITION;
                float3 normal       : NORMAL;
                float3 color        : COLOR;
                float2 texcoord     : TEXCOORD;
            };

            struct Varyings
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD;
                float3 diffuse      : TEXCOORD1;
                float3 color        : TEXCOORD2;
                float3 ambient      : TEXCOORD3;
            };

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _BaseMap_ST;
            CBUFFER_END

            void rotate2D(inout float2 v, float r)
            {
                float s, c;
                sincos(r, s, c);
                v = float2(v.x * c - v.y * s, v.x * s + v.y * c);
            }

            Varyings vert (Attributes v , uint instanceID:SV_InstanceID)
            {
                UNITY_SETUP_INSTANCE_ID(v)
                Varyings o = (Varyings) 0;

                #if SHADER_TARGET >= 45
                    float4 data = positionBuffer[instanceID];
                #else
                    float4 data = 0;
                #endif
                
                float rotation = data.w * data.w * _Time.x * 0.5f;
                rotate2D(data.xz, rotation);

                float3 localPosition = v.positionOS.xyz * data.w;
                float3 worldPosition = data.xyz + localPosition;
                float3 worldNormal = v.normal;

                o.positionHCS = TransformWorldToHClip(worldPosition);

                //这里获取光的位置没有使用引擎内置函数，而知直接使用了内置函数里面使用的API
                float3 NdotL = saturate(dot(worldNormal, _MainLightPosition.xyz));

                o.diffuse = NdotL * _MainLightColor.rgb;
                o.ambient = SampleSH(worldNormal);
                o.color = v.color;
                
                o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                UNITY_TRANSFER_INSTANCE_ID(v, o)
                half4 FinalColor;

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap , i.uv);

                FinalColor = float4(baseMap.rgb * i.diffuse + i.ambient , 1.0);
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
