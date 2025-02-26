Shader "Art_URP/FunctionTest/BlcakHole"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RightX ("Right X", Float) = 1
        _LeftX ("Left X", Float) = 0
        _Control ("Control", Range(0, 2)) = 0
        _BlackHolePos("Black Hole Pos",Vector) = (1,1,1,1)      //这里的值可以通过脚本来控制，如果不用脚本控制，就在shader的属性面板中输入希望吸收的目标位置坐标值
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
                float4 _MainTex_ST;
                float  _RightX;
                float  _LeftX;
                float  _Control;
                float4 _BlackHolePos;
            CBUFFER_END

            float GetNormalizeDist(float worldY)
            {
                float range = _RightX - _LeftX;
                float distance = _RightX - worldY;
                return saturate(distance / range);
            }

            Varyings vert (Attributes v)
            {
                UNITY_SETUP_INSTANCE_ID(v);

                Varyings o = (Varyings)0;
                //将模型的顶点变换到世界空间，然后在执行对顶点的操作，最后将操作过后的本地空间下的顶点变换到世界空间
                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                float normalizeDist = GetNormalizeDist(positionWS.x);

                float3 toBlackHole = TransformWorldToObjectDir(_BlackHolePos - positionWS.xyz);
                float3 value = saturate(_Control - normalizeDist);
                v.positionOS.xyz += toBlackHole * value;

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
                clip(_BlackHolePos.x - i.positionWS.x);

                FinalColor =mainMap;

                return FinalColor;
            }
            ENDHLSL
        }
    }
}

