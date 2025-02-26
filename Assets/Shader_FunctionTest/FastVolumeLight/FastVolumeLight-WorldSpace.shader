Shader "Art_URP/FunctionTest/FastVolumeLight-WorldSpace"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode ("CullMode", float) = 2

        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _Radius ("_Radius", Float) = 10
        _Soft ("Soft", Range(0, 10)) = 0.5
        _Smooth ("Smooth", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" }
        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            ZTest Off
            Blend One One
            Cull [_CullMode]
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/ShaderLibs/Node.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float4 screenPos : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
            };

            TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
                half _Radius;
                half _Soft;
                half _Smooth;
            CBUFFER_END
            
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                
                o.positionHCS = TransformObjectToHClip(v.positionOS);
                o.screenPos = ComputeScreenPos(o.positionHCS);
                o.positionWS = mul(unity_ObjectToWorld, v.positionOS);

                return o;
            }
            
            half4 frag(Varyings i) : SV_Target
            {
                half2 screenUV = i.screenPos.xy / i.screenPos.w;
                float sceneDepth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture , screenUV);
                sceneDepth = LinearEyeDepth(sceneDepth,_ZBufferParams);

                float3 cameraDir = -normalize(UNITY_MATRIX_V[2].xyz);
                float3 ce = float3(unity_ObjectToWorld[0].w, unity_ObjectToWorld[1].w, unity_ObjectToWorld[2].w);
                float3 rd = -normalize(GetWorldSpaceViewDir(i.positionWS));
                float3 ro = _WorldSpaceCameraPos.xyz;
                float  ra = _Radius;

                float SceneDistance = sceneDepth / dot(rd, cameraDir);

                //与Sphere相交
                float3 oc = ro - ce;
                float b = dot(oc, rd);
                float c = dot(oc, oc) - ra * ra;
                float h = b * b - c;
                if (h < 0) return 0;//判断出未相交则返回0
                h = sqrt(h);

                float2 sphere = float2(-b - h, -b + h);
                sphere.x = max(sphere.x, 0);
                sphere.y = min(sphere.y, SceneDistance);//处理深度遮挡
                float3 mid = ro + rd * (sphere.x + sphere.y) * 0.5;//获得中点
                float dist = 1 - (distance(mid, ce) / ra); //以中点距离球心的距离作为亮度

                dist = dist / _Soft;
                dist = SmoothValue(dist, 0.5, _Smooth);
                return dist * _Color;
            }
            ENDHLSL
        }
    }
}

