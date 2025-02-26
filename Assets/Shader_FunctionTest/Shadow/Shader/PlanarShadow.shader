Shader "Art_URP/FunctionTest/PlanarShadow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        [Header(Shadow)]
        _GroundHeight ("_GroundHeight", Float) = 0
        _ShadowColor ("_ShadowColor", Color) = (0, 0, 0, 1)
        _ShadowFalloff ("_ShadowFalloff", Range(0, 1)) = 0.05
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }

        //MainColor Pass 
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
            };

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float  _GroundHeight;
                float4 _ShadowColor;
                float  _ShadowFalloff;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 mainMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                return mainMap;
            }
            ENDHLSL
        }

        //阴影Pass
        pass
        {
            Name "PlanarShadow"
            Tags { "LightMode" = "UniversalForward" }
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite off
            //深度稍微偏移防止阴影与地面穿插
            Offset -1, 0

            //用使用模板测试以保证alpha显示正确
            Stencil
            {
                Ref 0
                Comp equal
                Pass incrWrap
                Fail keep
                ZFail keep
            }

            HLSLPROGRAM
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            #pragma vertex vert
            #pragma fragment frag
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float4 positionHCS: SV_POSITION;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            CBUFFER_START(UnityPerMaterial)
                half  _GroundHeight;
                half4 _ShadowColor;
                half  _ShadowFalloff;
            CBUFFER_END
            
            float3 ShadowProjectPos(float3 positionOS)
            {
                float3 positionWS = TransformObjectToWorld(positionOS);
                
                //灯光方向
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);
                
                //阴影的世界空间坐标（低于地面的部分不做改变）
                float3 shadowPos;
                shadowPos.y = min(positionWS.y, _GroundHeight);
                shadowPos.xz = positionWS.xz - lightDir.xz * max(0, positionWS.y - _GroundHeight) / lightDir.y;
                
                return shadowPos;
            }

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                
                //得到阴影的世界空间坐标
                float3 shadowPos = ShadowProjectPos(v.positionOS.xyz);
                //转换到裁切空间
                o.positionHCS = TransformWorldToHClip(shadowPos);
                
                //得到中心点世界坐标
                float3 center = float3(unity_ObjectToWorld[0].w, _GroundHeight, unity_ObjectToWorld[2].w);
                //计算阴影衰减
                float falloff = 1 - saturate(distance(shadowPos, center) * _ShadowFalloff);

                o.color = _ShadowColor;
                o.color.a *= falloff;
                
                return o;
            }
            
            half4 frag(Varyings i): SV_Target
            {
                return i.color;
            }
            ENDHLSL
        }
    }
}
