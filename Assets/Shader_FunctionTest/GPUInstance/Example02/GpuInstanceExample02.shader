Shader "Art_URP/FunctionTest/InstancedShader02"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
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

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID // 只有当你想访问片段着色器中的实例属性时才有必要。
            };

            // 常规定义属性
			// float4 _Color;

            // Instance 定义属性
            #ifdef UNITY_INSTANCING_ENABLED     //在材质面板勾选GPU实例化选项
                UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
                UNITY_INSTANCING_BUFFER_END(Props)
            #else
                float4 _Color;
            #endif

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o); // 只有当你想要访问片段着色器中的实例属性时才需要。

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i); // 只有当你想要访问片段着色器中的实例属性时才需要。
                return UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                // return _Color;
            }
            ENDHLSL
        }
    }
}