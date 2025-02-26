Shader "Art_URP/FunctionTest/Parallax"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _BaseMap("BaseMap" , 2D) = "white"{}
        _NormalMap("NormalMap",2D) = "bump"{}
        _BumpScale("BumpScale",float) = 1
        
        _SpecularColor("SpecularColor" , Color) = (1,1,1,1)
        _SpecularMask("SpecularMask" , 2D) = "white"{}
        [PowerSlider(20)]_SpecularPow("SpecularPow",Range(2,255)) = 2
        _SpecularIntensity("SpecularIntensity" , float) = 1

        _AoMap("AoMap",2D) = "white"{}

        _ParallaxMap("ParallaxMap",2D) = "black"{}
        _Parallax("Parallax",float) = 2
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry"}

        LOD 100

        pass
        {
            Tags{"RenderPipeline" = "UniversalPipeline"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD;
                float3 positionWS   : TEXCOORD1;
                float3 normalWS     : TEXCOORD2;
                float3 viewWS       : TEXCOORD3;
                float3 tangentWS    : TEXCOORD4;
                float3 bitangentWS  : TEXCOORD5;
            };
            
            //属性定义部分
            //定义纹理采样贴图和采样状态
            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D(_SpecularMask);SAMPLER(sampler_SpecularMask);
            TEXTURE2D(_NormalMap);SAMPLER(sampler_NormalMap);
            TEXTURE2D(_AoMap);SAMPLER(sampler_AoMap);
            TEXTURE2D(_ParallaxMap);SAMPLER(sampler_ParallaxMap);

            //CBuffer部分，数据参数定义在该结构内，可以使用srp的batch功能
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _BaseMap_ST;
                float4 _NormalMap_ST;
                float  _BumpScale;
                float4 _SpecularMask_ST;
                float4 _SpecularColor;
                float  _SpecularPow;
                float  _SpecularIntensity;
                float4 _AoMap_ST;
                float  _Parallax;
                float4 _ParallaxMap_ST;
            CBUFFER_END

            float3 ACESFilm(float3 x)
			{
				float a = 2.51f;
				float b = 0.03f;
				float c = 2.43f;
				float d = 0.59f;
				float e = 0.14f;
				return saturate((x*(a*x + b)) / (x*(c*x + d) + e));
			};

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);

                o.tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);
                half signDir = real(v.tangentOS.w) * GetOddNegativeScale();
                o.bitangentWS = cross(o.normalWS , o.tangentWS) * signDir;

                o.viewWS = GetWorldSpaceViewDir(o.positionWS);

                o.uv = TRANSFORM_TEX(v.texcoord , _BaseMap);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;
                half3 AmbientColor =  _GlossyEnvironmentColor.rgb;

                Light light = GetMainLight(TransformWorldToShadowCoord(i.positionWS));
                half3 lightColor = light.color * light.distanceAttenuation;
                half3 lightDir = light.direction;

                //向量计算
                // half3 worldNormalDir = normalize(i.normalWS);            //这里的法线使用了模型的顶点法线信息
                //通过TBN矩阵，将法线贴图的数据从切线空间转换到世界空间
                float3x3 TBN = float3x3(normalize(i.tangentWS.xyz) ,normalize(i.bitangentWS.xyz)  , normalize(i.normalWS.xyz));
                half3 worldViewDir = normalize(i.viewWS);
                half3 tangentViewDir = normalize(mul(TBN,worldViewDir));
                half2 uv = i.uv;

                //注意这里不用使用i来定义，否则会报错
                for (int j = 0; j < 10; j++)
				{
					half height = SAMPLE_TEXTURE2D(_ParallaxMap , sampler_ParallaxMap , uv);
					uv = uv - (0.5 - height) * tangentViewDir.xy * _Parallax * 0.01f;
				}

                //纹理采样
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,uv);
                half4 specularMap = SAMPLE_TEXTURE2D(_SpecularMask , sampler_SpecularMask , uv);
                half4 ambientMap = SAMPLE_TEXTURE2D(_AoMap,sampler_AoMap,uv);
                half4 NormalMap = SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap , uv);
                half3 normalTS = UnpackNormalScale(NormalMap,_BumpScale);
                half3 worldNormalDir = normalize(TransformTangentToWorld(normalTS , TBN));
                
                half3 reflectDir = reflect(-lightDir , worldNormalDir);
                half3 halfDir = normalize(lightDir + worldViewDir);

                //颜色计算
                half3 ambientColor = AmbientColor * baseMap;
                half3 diffuseColor = max(0.0 , (dot(lightDir , worldNormalDir) * 0.5 + 0.5)) * lightColor * baseMap.rgb * _Color.rgb;
                half3 specularColor = pow(max(0.0 , dot(worldNormalDir,halfDir)) , _SpecularPow) * lightColor * specularMap.rgb * _SpecularIntensity;

                //支持额外光源
                int additionalLightCount = GetAdditionalLightsCount(); //获取额外光源数量
                for(int lightIndex = 0; lightIndex < additionalLightCount; ++lightIndex)
                {
                    light = GetAdditionalLight(lightIndex , i.positionWS);     //根据Index获取额外的光源数据
                    half3 attenuatedLightColor = light.color * light.distanceAttenuation;
                    //叠加漫反射和高光
                    diffuseColor  += LightingLambert(attenuatedLightColor , light.direction , worldNormalDir) * baseMap;
                    specularColor += LightingSpecular(attenuatedLightColor , light.direction , worldNormalDir , worldViewDir , _SpecularColor , _SpecularPow) * specularMap;
                }

                //颜色混合
                half3 TotalLight = ambientColor + diffuseColor + specularColor;
                half3 tone_Color = ACESFilm(TotalLight);
                FinalColor = half4(tone_Color , 1.0);
                return FinalColor;
            }
            ENDHLSL  
        }

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
