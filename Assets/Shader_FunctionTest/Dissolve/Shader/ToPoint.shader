Shader "Art_URP/FunctionTest/ToPoint"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
        _NoiseTex ("Noise Tex", 2D) = "white" { }
        [HideInInspector]_Threshold ("Threshold", Range(0, 1)) = 0
        _EdgeLength("EdgeLength" , Range(0.0 , 0.2)) = 0.1
        _RampTex("RampTex",2D) = "white"{}

        [HideInInspector]_StartPoint("StartPoint",vector) = (1,1,1,1)        //开始点的世界坐标
        [HideInInspector]_MaxDistance("MaxDistance",float) = 0
        [HideInInspector]_DistanceEffect("DistanceEffect" , Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        LOD 100

        pass
        {
            Tags{"RenderPipeline" = "UniversalPipeline"}
            Cull off

            HLSLPROGRAM

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
                float3 normal       : NORMAL;
            };

            struct Varyings
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 positionHCS  : SV_POSITION;
                float4 uv           : TEXCOORD0;
                float3 worldPosition: TEXCOORD1;
                float3 worldNormal  : TEXCOORD2;
            };

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);   SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_RampTex);   SAMPLER(sampler_RampTex);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _NoiseTex_ST;
                float  _Threshold;
                float  _EdgeLength;

                float4 _StartPoint;
                float  _MaxDistance;
                float  _DistanceEffect;
            CBUFFER_END
           
            Varyings vert (Attributes v)
            {
                UNITY_SETUP_INSTANCE_ID(v);

                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv.xy = TRANSFORM_TEX(v.texcoord , _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord , _NoiseTex);

                o.worldPosition = TransformWorldToObject(v.positionOS.xyz);
                o.worldNormal = TransformObjectToWorldNormal(v.normal);        //将开始点的坐标从世界空间转换到模型空间
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                // UNITY_SETUP_INSTANCE_ID(i);

                half4 FinalColor;

                //主方向光
                Light mainLight = GetMainLight();
                half3 LightDir = normalize(mainLight.direction);

                //向量
                half3 normalWS = normalize(i.worldNormal);

                half distance = length(i.worldPosition - _StartPoint.xyz);
                half normalizeDistance = 1 - saturate(distance/_MaxDistance);

                half noiseMap = SAMPLE_TEXTURE2D(_NoiseTex , sampler_NoiseTex , i.uv.zw).r * (1 - _DistanceEffect) + normalizeDistance * _DistanceEffect;
                clip(noiseMap - _Threshold);
                
                half  degree = saturate((noiseMap - _Threshold) / _EdgeLength);
                half4 edgeColor = SAMPLE_TEXTURE2D(_RampTex , sampler_RampTex , half2(degree,degree));  //使用noise贴图的黑白作为RampTex的uv来采样

                half4 mainMap = SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , i.uv.xy);

                half3 diffuse = mainLight.color.rgb * mainMap.rgb * saturate(dot(LightDir,normalWS));
            
                FinalColor = half4(lerp(edgeColor , half4(diffuse , 1.0) , degree).rgb , 1.0);
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
