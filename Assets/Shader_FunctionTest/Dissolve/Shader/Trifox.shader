Shader "Art_URP/FunctionTest/Trifox"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
        _NoiseTex ("Noise Tex", 2D) = "white" { }
        [NoScaleOffset]_ScreenSpaceMaskTex ("Screen Space Mask", 2D) = "white" { }
        _WorkDistance ("Work Distance", Float) = 0                              //消融角色的范围大小
        [HideInInspector]_PlayerPos ("Player Pos", Vector) = (0, 0, 0, 0)       //获取player的坐标
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline"  "Queue" = "Geometry" "RenderType" = "Opaque" "IgnoreProjector" = "True" }
        LOD 100

        Pass
        {
            Tags{"RenderPipeline" = "UniversalPipeline"}
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

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
                float3 positionWS   : TEXCOORD1;
                float4 positionNDC  : TEXCOORD2;
                float2 uv1          : TEXCOORD3;
            };

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);   SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_ScreenSpaceMaskTex);   SAMPLER(sampler_ScreenSpaceMaskTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _NoiseTex_ST;
                float  _WorkDistance;
                float4 _PlayerPos;
            CBUFFER_END
            
            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                //GetVertexPositionInputs函数在ShaderVariablesFunctions.hlsl中，该函数用于输出世界空间、视口空间、裁剪空间以及NDC空间下的坐标信息
                //GetVertexPositionInputs函数的返回值是VertexPositionInputs类型
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);   
                o.positionHCS = vertexInput.positionCS;
                o.positionWS = vertexInput.positionWS;
                o.positionNDC = vertexInput.positionNDC;
                
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv1 = TRANSFORM_TEX(v.texcoord , _NoiseTex);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                float toCamera = distance(i.positionWS, _WorldSpaceCameraPos);          //遮挡物体离相机的距离
                float playerToCamera = distance(_PlayerPos.xyz, _WorldSpaceCameraPos);  //player物体离相机的距离

                float2 wcoord = i.positionNDC.xy / i.positionNDC.w;     //NDC空间下的uv坐标
                float  mask = SAMPLE_TEXTURE2D(_ScreenSpaceMaskTex, sampler_ScreenSpaceMaskTex , wcoord).r;
                
                float  noiseMap = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv1).r;
                half4  mainMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                
                //如果遮挡物体的距离小于相机的距离，则对物体进行裁剪
                if (toCamera < playerToCamera)          
                {
                    clip(noiseMap - mask + (toCamera - _WorkDistance) / _WorkDistance);
                }
                
                FinalColor = mainMap;

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
