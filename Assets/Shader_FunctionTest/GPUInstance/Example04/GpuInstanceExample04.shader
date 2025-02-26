Shader "Art_URP/FunctionTest/InstancedShader3" {
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

            StructuredBuffer<float4x4> localToWorldBuffer;

            struct Attributes
            {
                float4 vertex : POSITION;
                // UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 vertex : SV_POSITION;
                // UNITY_VERTEX_INPUT_INSTANCE_ID // 只有当你想访问片段着色器中的实例属性时才有必要。
            };

            // 常规定义属性
            float4 _Color;

            // Instance 定义属性
            // UNITY_INSTANCING_BUFFER_START(Props)
            // UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
            // UNITY_INSTANCING_BUFFER_END(Props)

            Varyings vert(Attributes v, uint instanceID : SV_InstanceID)
            {
                Varyings o= (Varyings)0;
                // UNITY_SETUP_INSTANCE_ID(v);
                // UNITY_TRANSFER_INSTANCE_ID(v, o); // 只有当你想要访问片段着色器中的实例属性时才需要。
                // 根据instanceID获取变换矩阵
                float4x4 localToWorldMatrix = localToWorldBuffer[instanceID];
                // 变换到世界空间
                float4 positionWS = mul(localToWorldMatrix,v.vertex);
                // 变换到ndc空间
                positionWS /= positionWS.w;
                // 变换到裁剪空间
                o.vertex = mul(UNITY_MATRIX_VP,positionWS);
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                // UNITY_SETUP_INSTANCE_ID(i); // 只有当你想要访问片段着色器中的实例属性时才需要。
                // return UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                return _Color;
            }
            ENDHLSL
        }
    }
}