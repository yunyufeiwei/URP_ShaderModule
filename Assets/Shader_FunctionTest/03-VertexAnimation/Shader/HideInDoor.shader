Shader "Art_URP/FunctionTest/HideInDoor"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TopY ("Top Y", Float) = 1
        _BottomY ("Bottom Y", Float) = 0
        _Control ("Control", Range(0, 2)) = 0
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            
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
                float3 positionWS   : TEXCOORD1;
            };

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float  _TopY;
                float _BottomY;
                float _Control;
            CBUFFER_END

            float GetNormalizeDist(float worldY)
            {
                float range = _TopY - _BottomY;
                float distance = _TopY - worldY;
                return saturate(distance / range);
            }

            Varyings vert (Attributes v)
            {
                UNITY_SETUP_INSTANCE_ID(v);

                Varyings o = (Varyings)0;
                //将模型的顶点变换到世界空间，然后在执行对顶点的操作，最后将操作过后的本地空间下的顶点变换到世界空间
                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                float normalizeDist = GetNormalizeDist(positionWS.y);
                float3 localNegativeY = TransformWorldToObjectDir(float3(0, 1, 0));        //局部坐标的负Y方向
                float3 value = saturate(_Control - normalizeDist);
                v.positionOS.xyz += localNegativeY * value;

                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.texcoord;
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                half4 FinalColor;

                half4 mainMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv);
                clip(_TopY - i.positionWS.y);

                FinalColor =mainMap;

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
