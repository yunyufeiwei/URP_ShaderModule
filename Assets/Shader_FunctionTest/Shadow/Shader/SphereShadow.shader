Shader "Art_URP/FunctionTest/Sphere Shadow"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
        _ShadowFalloff ("_ShadowFalloff", Float) = 0.05
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            Cull Off
            
            HLSLPROGRAM
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            #pragma vertex vert
            #pragma fragment frag
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
            };
            
            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float3 positionWS   : TEXCOORD1;
                float4 positionCS   : SV_POSITION;
            };

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half _ShadowFalloff;
                
                float4 _SpherePos;
                float _SphereRadius;
            CBUFFER_END
            
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionWS = vertexInput.positionWS;
                o.positionCS = vertexInput.positionCS;
                
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                
                return o;
            }
            
            half4 frag(Varyings i): SV_Target
            {
                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);
                
                float3 toSphere = normalize(_SpherePos.xyz - i.positionWS);
                float angle = acos(dot(lightDir, toSphere));//到圆向量和到光源向量的夹角
                
                float distToSphere = length(_SpherePos.xyz - i.positionWS);
                float maxAngle = atan(_SphereRadius / distToSphere);//圆覆盖的角度
                
                if (angle < maxAngle)//处于圆覆盖的范围
                {
					half atten = (angle / maxAngle)  / _ShadowFalloff;
					return smoothstep(0, 1, atten);
                }
                else
                {
                    half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                    return col;
                }
            }
            ENDHLSL
        }
    }
}
