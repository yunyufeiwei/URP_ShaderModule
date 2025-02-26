Shader "Catlikecoding/FirstLight"
{
    Properties
    {
        _Color("Color" , Color) = (1,1,1,1)
        _BaseMap ("BaseMap", 2D) = "white" {}
        _Smoothness("Smoothness",Range(0,1)) = 0.5
        _Metallic("Metallic",Range(0,1)) = 0
        
        _HeightMap("HeightMap",2D) = "bump"{}

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
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/Catlikecoding/ShadLib/InputData.hlsl"

            //顶点着色器输入结构体
            struct AttributesData
            {
               float4 positionOS   : POSITION;
               float3 normalOS     : NORMAL;
               float2 texcoord     : TEXCOORD;
            };
            //顶点着色器输出结构体
            struct VaryingsData
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD;
                float3 normalWS     : TEXCOORD1;
                float3 viewWS       : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _BaseMap_ST;
                float  _Smoothness;
                float  _Metallic;
                float4 _HeightMap_TexelSize;
            CBUFFER_END

            void InitializeFragmentNormal(inout VaryingsData i)
            {
                float2 du = float2(_HeightMap_TexelSize.x * 0.5, 0);
                float u1 = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap , i.uv - du);
                float u2 = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap , i.uv + du);
                // float3 tu = float3(1 , u2 - u1 , 0);
                
                float2 dv = float2(0, _HeightMap_TexelSize.y * 0.5);
                float v1 = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap , i.uv - dv);
                float v2 = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap , i.uv + dv);
                // float3 tv = float3(0, v2 - v1 , 1);
                
                // i.normalWS = cross(tv,tu);
                i.normalWS = float3(u1 - u2 , 1 , v1 - v2);
                i.normalWS = normalize(i.normalWS);
            }
            
            //顶点着色器
            VaryingsData vert (AttributesData v)
            {
                VaryingsData o = (VaryingsData) 0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS);

                o.positionHCS = vertexInput.positionCS;
                o.normalWS = normalInput.normalWS;
                o.viewWS = GetWorldSpaceViewDir(vertexInput.positionWS);

                o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
                return o;
            }

            //像素着色器
            half4 frag (VaryingsData i) : SV_Target
            {
                half4 FinalColor;
                InitializeFragmentNormal(i);

                Light light = GetMainLight();
                half4 lightColor = half4(light.color * light.distanceAttenuation, 1.0);
                half3 lightDirWS = light.direction;

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap , i.uv);

                // half4 bumpMap = InitializeFragmentNormal(i);

                half3 worldNormalDir = normalize(i.normalWS);
                half3 worldViewDir = normalize(i.viewWS);
                half3 reflectionDir = reflect(-lightDirWS,worldNormalDir);
                half3 halfDir = saturate(normalize(lightDirWS + worldViewDir));
                
                half lambert = saturate(dot(lightDirWS,worldNormalDir));
                half blinnPhone = pow(saturate(dot(halfDir,worldNormalDir)) , _Smoothness * 100 + 0.001);

                half4 diffuse =  baseMap * _Color * lightColor * lambert;

                FinalColor = lambert;
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
