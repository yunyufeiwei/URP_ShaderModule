Shader "Art_URP/FunctionTest/CustomMetallicPBR"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _Glossiness("Smoothness",Range(0.0,1.0)) = 0.5
        _MetallicGlossMap("MetallicMap" , 2D) = "white"{}
        _BumpScale("BumpScale" , float) = 1.0
        _BumpMap("BumpMap" , 2D) = "bump"{}
        _EmissionColor("EmissionColor" , Color)=(0,0,0,1)
        _EmissionMap("EmissionMap" , 2D) = "white"{}
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" "RenderType" = "Opaque"  "IgnoreProjector" = "True" }
        LOD 100

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID          //GPU实例化
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
            };

            struct Varyings
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID          //GPU实例化
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float4 TtoW0        : TEXCOORD1;
                float4 TtoW1        : TEXCOORD2;
                float4 TtoW2        : TEXCOORD3;
                float fogFactor     : TEXCOORD4;
                float4 shadowCoord  : TEXCOORD5;
            };
            
            //声明纹理并对纹理采样
            TEXTURE2D(_MainTex);            SAMPLER(sampler_MainTex);
            TEXTURE2D(_MetallicGlossMap);   SAMPLER(sampler_MetallicGlossMap);
            TEXTURE2D(_BumpMap);            SAMPLER(sampler_BumpMap);
            TEXTURE2D(_EmissionMap);        SAMPLER(sampler_EmissionMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _MainTex_ST;
                float  _Glossiness;
                float4 _MetallicGlossMap_ST;
                float  _BumpScale;
                float4 _BumpMap_ST;
                float4 _EmissionColor;
                float4 _EmissionMap_ST;
            CBUFFER_END

            //inline关键字用来定义一个类的内联函数，引入它的主要原因是用它替代C中表达式形式的宏定义
            inline float3 CustomDisneyDiffuseTerm(half NdotV , half NdotL , half LdotH , half roughness , half3 baseColor)
            {
                //Disney漫反射模型与不考虑表面粗糙度的Lambert漫反射模型实际效果区别不大，所以在Unity的第2,3档中diffuse计算用的是更简单的Lambert模型。
                half fd90 = 0.5 + 2 * LdotH * LdotH * roughness;
                half lightScatter = 1 + (fd90 - 1) * pow(1 - NdotL , 5);
                half viewScatter = 1 + (fd90 -1) * pow(1 - NdotV , 5);
                return baseColor * INV_PI * lightScatter * viewScatter;
            }

            inline float CustomSmithJointGGXVisibilityTerm(half NdotL , half NdotV , half roughness)
            {
                half a2 = roughness * roughness;
                half lambdaV = NdotL * (NdotV * (1 - a2) + a2);
                half lambdaL = NdotV * (NdotL * (1 - a2) + a2);
                return 0.5f / (lambdaV + lambdaL + 1e-5f);
            }

            inline half CustomGGXTerm(half NdotH, half roughness)
            {
                half a2 = roughness * roughness;
                half d = (NdotH * a2 - NdotH) * NdotH + 1.0f;
                return INV_PI * a2 / (d * d + 1e-7f);
            }

            inline half3 CustomFresnelTerm(half3 c, half cosA)
            {
                half t = pow(1 - cosA, 5);
                return c + (1 - c) * t;
            }
            
            inline half3 CustomFresnelLerp(half3 c0, half3 c1, half cosA)
            {
                half t = pow(1 - cosA, 5);
                return lerp(c0, c1, t);
            }

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                //GetVertexPositionInputs函数在ShaderVariablesFunctions.hlsl里面定义，返回类型是一个包含了(世界、视口、裁剪、NDC空间)坐标信息
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                //GetVertexNormalInputs函数在ShaderVariablesFunctions.hlsl里面定义，返回类型是一个结构体，包含了世界空间下的法线、切线与副切线信息
                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS , v.tangentOS);

                o.positionHCS = vertexInput.positionCS;

                o.TtoW0 = float4(normalInput.tangentWS.x , normalInput.bitangentWS.x , normalInput.normalWS.x , vertexInput.positionWS.x);
                o.TtoW1 = float4(normalInput.tangentWS.y , normalInput.bitangentWS.y , normalInput.normalWS.y , vertexInput.positionWS.y);
                o.TtoW2 = float4(normalInput.tangentWS.z , normalInput.bitangentWS.z , normalInput.normalWS.z , vertexInput.positionWS.z);

                o.uv = TRANSFORM_TEX(v.texcoord , _MainTex);
                
                o.fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
                
                o.shadowCoord = GetShadowCoord(vertexInput);

                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                Light Light = GetMainLight(i.shadowCoord);
                half3 lightDirWS = Light.direction;
                half3 lightCoflor = Light.color * Light.distanceAttenuation * Light.shadowAttenuation;

                half3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb * _Color.rgb;
                //法线信息
                half3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.uv));
                normalTS.xy *= _BumpScale;
                normalTS.z = sqrt(1.0 - saturate(dot(normalTS.xy , normalTS.xy)));
                half3 normalWS = normalize(half3(dot(i.TtoW0.xyz , normalTS.xyz) , dot(i.TtoW1.xyz , normalTS.xyz) , dot(i.TtoW2.xyz , normalTS.xyz)));
                //
                half4 metallicMap = SAMPLE_TEXTURE2D(_MetallicGlossMap , sampler_MetallicGlossMap , i.uv);
                half  metallic = metallicMap.r;                     //金属性
                half  smoothness = metallicMap.a * _Glossiness;     //光滑度(值越大越光滑，也就是反射效果越强)
                half  roughness = 1.0 - smoothness;                 //粗糙度，金属性越强（smoothness值越大反射越强）的地方，粗糙度越低

                half oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);     //漫反射率（如果是金属，漫反射率比较低，0.04）,该函数在DRDF.hlsl里面
                half3 diffuseColor = albedo * oneMinusReflectivity;
                half3 specularColor = lerp(kDielectricSpec.rgb , albedo , metallic);

                float3 positionWS = float3(i.TtoW0.w , i.TtoW1.w , i.TtoW2.w);
                float3 viewDirWS = normalize(_WorldSpaceCameraPos - positionWS);
                float3 reflectDirWS = reflect(-viewDirWS , normalWS);

                //准备BRDF需要的项
                half3 halfDir = normalize(lightDirWS + viewDirWS);
                half NdotV = saturate(dot(normalWS , viewDirWS));
                half NdotL = saturate(dot(normalWS , lightDirWS));
                half NdotH = saturate(dot(normalWS , halfDir));
                half LdotV = saturate(dot(lightDirWS , viewDirWS));
                half LdotH = saturate(dot(lightDirWS , halfDir));

                //D项(Diffuse Term)
                half3 diffuseTerm = CustomDisneyDiffuseTerm(NdotV , NdotL , LdotH , roughness , diffuseColor);

                //G项(Specular Term)
                half V = CustomSmithJointGGXVisibilityTerm(NdotL , NdotV , roughness);
                half D = CustomGGXTerm(NdotH , roughness * roughness);
                half3 F = CustomFresnelTerm(specularColor, LdotH);
                half3 specularTerm = F * V * D;

                half3 emissionTerm = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, i.uv).rgb * _EmissionColor.rgb;

                //IBL
                half  perceptualRoughness = roughness * (1.7 - 0.7 * roughness);
                half  mip = perceptualRoughness * 6;
                half3 envMap = DecodeHDREnvironment(SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDirWS, mip) , unity_SpecCube0_HDR);
                half  grazingTerm = saturate((1 - roughness) + (1 - oneMinusReflectivity));
                half  surfaceReduction = 1.0 / (roughness * roughness + 1.0);
                half3 indirectSpecular = surfaceReduction * envMap.rgb * CustomFresnelLerp(specularColor, grazingTerm, NdotV);

                half4 FinalColor = half4(emissionTerm + PI * (diffuseTerm + specularTerm) * NdotL * lightCoflor + indirectSpecular , 1.0);

                FinalColor.rgb = MixFog(FinalColor.rgb, i.fogFactor);

                // return half4(normalTS,1.0);
                return FinalColor;
            }
            ENDHLSL
        }   

        //渲染物体的阴影生成
        Pass
        {
            Name "ShadowCaster"
            Tags {"LightMode" = "ShadowCaster"}

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
            };
            struct Varyings
            {
                float4 positionCS  : SV_POSITION;       //裁剪空间的维度是四维的
            };

            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings) 0;

                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(v.normalOS);

                //\Library\PackageCache\com.unity.render-pipelines.universal@14.0.8\Editor\ShaderGraph\Includes\Varyings.hlsl
                //获取阴影专用裁剪空间下的坐标
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, float3(0,0,0)));
                //判断是否在DirectX平台翻转过坐标
                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                    o.positionCS = positionCS;

                return o;
            }

            half4 frag(Varyings input) : SV_TARGET
            {
                return 0;
            }
            ENDHLSL
        }
    }
}
