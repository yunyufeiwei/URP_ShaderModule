Shader "Art_URP/FunctionTest/FastVolumeLight-ObjectSpace"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode ("CullMode", float) = 2

        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _Radius ("_Radius", Float) = 0.5
        _Soft ("Soft", Range(0, 10)) = 0.5
        _Smooth ("Smooth", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" }
        ZTest Off
        Blend One One
        Cull [_CullMode]
        
        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
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
                float3 positionOS : TEXCOORD1;
                float3 positionWS : TEXCOORD3;
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
                Varyings o=(Varyings)0;
                
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionOS = v.positionOS.xyz;
                o.positionWS = TransformObjectToWorld(o.positionOS);
                o.screenPos = ComputeScreenPos(o.positionHCS);
                
                return o;
            }

            // https://iquilezles.org/articles/intersectors/
            // 与球相交
            float2 SphereIntersect(float3 ro, float3 rd, float3 ce, float ra)
            {
                float3 oc = ro - ce;
                float b = dot(oc, rd);
                float c = dot(oc, oc) - ra * ra;
                float h = b * b - c;
                if (h < 0) return 0;//判断出未相交则返回0
                h = sqrt(h);
            
                // 返回两个相交点(距离)
                return float2(-b - h, -b + h);
            }
            
            half4 frag(Varyings i) : SV_Target
            {
                half2 screenUV = i.screenPos.xy / i.screenPos.w;
                float3 cameraOS = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos.xyz, 1)).xyz;
                float3 viewDirOS = normalize(i.positionOS - cameraOS.xyz);
                float3 viewDirWS = normalize(i.positionWS - _WorldSpaceCameraPos.xyz);
                
                float sceneDepth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture , screenUV).r;
                sceneDepth = LinearEyeDepth(sceneDepth , _ZBufferParams);

                float3 cameraDir = -normalize(mul(unity_WorldToObject, float4(UNITY_MATRIX_V[2].xyz, 0)).xyz);
                // float3 cameraDir = -normalize(UNITY_MATRIX_V[2].xyz);
                float3 rayDir = viewDirOS;
                float3 rayOrigin = cameraOS;

                float sceneDistance = sceneDepth / dot(viewDirOS, cameraDir);

                //与Sphere相交
                float2 sphere = SphereIntersect(rayOrigin, rayDir, 0, _Radius);
                sphere.x = max(sphere.x, 0);
                sphere.y = min(sphere.y, sceneDistance);//处理深度遮挡

                //相交中点
                float3 mid = rayOrigin + rayDir * ((sphere.x + sphere.y) * 0.5);

                //以中点距离球心的距离作为亮度
                float dist = 1 - length(mid) / _Radius;

                dist = dist / _Soft;
                dist = SmoothValue(dist, 0.5, _Smooth);
                return dist * _Color;
            }
            ENDHLSL
        }
    }
}

