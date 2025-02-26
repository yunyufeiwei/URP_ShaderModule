Shader "Art_URP/FunctionTest/CustomPBR_MRA"
{
    Properties
    {
        _AlbedoMap("BaseMap" , 2D) = "white"{}
        _DiffuseColor("DiffuseColor",color) = (1,1,1,1)
        
        _MaskMap("MRAMap" , 2D) = "white"{}
        _Roughness("Roughness",Range(0,1)) = 1
        _NormalMap("NormalLMap" , 2D) = "white"{}
        _NormalScale("NormalScale" , Float) = 1
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" "Queue" = "Geometry"}
        LOD 100

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "BRDFFunction.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 positionWS   : TEXCOORD1;
                float3 normalWS     : TEXCOORD2;
                float3 tangentWS    : TEXCOORD3;
                float3 bitangentWS  : TEXCOORD4;
                float3 viewWS       : TEXCOORD5;
            };

            TEXTURE2D(_BaseMap);  SAMPLER(sampler_BaseMap);
            TEXTURE2D(_MaskMap);  SAMPLER(sampler_MaskMap);
            TEXTURE2D(_NormalMap);SAMPLER(sampler_NormalMap);
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _MaskMap_ST;
                float4 _NormalMap_ST;
                float  _NormalScale;
                float  _Roughness;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionHCS = vertexInput.positionCS;
                o.positionWS = vertexInput.positionWS;

                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS , v.tangentOS);
                o.normalWS = normalInput.normalWS;
                o.tangentWS = normalInput.tangentWS;
                o.bitangentWS = normalInput.bitangentWS;

                o.viewWS = GetWorldSpaceViewDir(o.positionWS); 
                
                o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                Light light = GetMainLight();
                half3 lightDir = light.direction;
                half3 lightColor = light.color * light.distanceAttenuation;

                //构建TBN矩阵，采样纹理贴图
                float3x3 TBN = float3x3(i.tangentWS,i.bitangentWS,i.normalWS);
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap , sampler_BaseMap , i.uv);
                half4 maskMap = SAMPLE_TEXTURE2D(_MaskMap , sampler_MaskMap , i.uv);
                half4 normalMap = SAMPLE_TEXTURE2D(_NormalMap , sampler_NormalMap , i.uv);
                half3 normalTS = UnpackNormalScale(normalMap , _NormalScale);       //使用采样之后的法线贴图数据，解包成切线空间下的法线信息

                //向量计算
                float3 worldNormalDir = TransformTangentToWorld(normalTS , TBN);
                float3 worldViewDir = normalize(i.viewWS);
                float3 worldHalfDir = SafeNormalize(lightDir + worldViewDir);

                half NdotL = saturate(dot(worldNormalDir , lightDir));
                half NdotV = saturate(dot(worldNormalDir , worldViewDir));
                half NdotH = saturate(dot(worldNormalDir , worldHalfDir));
                half LdotH = saturate(dot(lightDir , worldHalfDir));
                
                //PBR参数准备
                half metallic = maskMap.r;
                half roughness = maskMap.g * _Roughness;    //_Roughness数值越小，越光滑
                
                half  oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);    //漫反射率（如果是金属，漫反射率比较低，0.04，非金属的漫反射率为0.96）,该函数在DRDF.
                half3 albedoColor = baseMap.rgb * oneMinusReflectivity;
                half3 specularColor = lerp(kDielectricSpec.rgb , baseMap,metallic);

                //直接光漫反射
                half3 diffuseColor = customDisneyDiffuse(NdotV , NdotL , LdotH , roughness , albedoColor);

                //直接光镜面反射
                half3 F_Term = FresnelSchlick(specularColor , NdotV);
                half  D_Term = NormalDistributionFunction(worldNormalDir , worldHalfDir , roughness);
                half  G_Term = GeometrySmith(worldNormalDir , worldViewDir , lightDir , roughness);
                // half3 specularTerm =  (D_Term * G_Term * F_Term) / (4 * NdotV * NdotL + 0.001); 

                FinalColor = half4(F_Term , 1.0);

                return G_Term;
            }
            ENDHLSL
        }
    }
}
