Shader "Art_URP/FunctionTest/Cloth_Diffuse"
{
    //属性
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _MainTex ("Main Tex", 2D) = "white" { }
    }
    SubShader
    {
        Tags {"RenderPipeline"="UniversalRenderPipeline" "RenderType"="Opaque" "Queue" = "Geometry"}
        
        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float4 position     : SV_POSITION;
                float3 normalWS     : TEXCOORD0;
                float4 uv           : TEXCOORD01;
            };

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
                half4 _MainTex_ST;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS);
                
                o.position = vertexInput.positionCS;
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.normalWS = normalInput.normalWS;

                return o;
            };


            half4 frag(Varyings i) : SV_TARGET
            {
                half4 FinalColor;
                Light light = GetMainLight();
                half3 lightColor = light.color * light.distanceAttenuation;
                half3 worldLightDir = light.direction;
                half3 worldNormalDir = normalize(i.normalWS);
                
                half3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                half3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex , i.uv.xy).rgb ;
                
                //半兰伯特漫反射  值范围0-1
                half3 halfLambert = dot(worldNormalDir, worldLightDir) * 0.5 + 0.5;

                half3 diffuseColor = lightColor * halfLambert * albedo * _Color + ambient;
                
                FinalColor = half4(diffuseColor, 1.0);

                return FinalColor;
            };
            
            ENDHLSL
        }
    }
}