Shader "Art_URP/Base/Light/HeightMap-ParallaxMapping(SelfShadow)"
{
    Properties
    {
        [Header(Base)]
        _BaseMap("BaseMap" , 2D) = "white"{}
        _BaseColor("BaseColor",Color) = (1,1,1,1)

        [Header(Specular)]
        _SpecularColor("SpecularColor" , Color) = (1,1,1,1)
        _SpecularPow("SpecularPow",Range(8,255)) = 20

        [Header(Normal)]
        _NormalMap("NormalMap",2D) = "bump"{}
        _NormalScale("NormalScale" , float) = 1

        [Header(Parallax)]
        _ParallaxMap("ParallaxMap",2D) = "white"{}
        _ParallaxScale("ParallaxScale" , float ) = 1
        _MinLayerCount("MinLayerCount",int) = 5
        _MaxLayerCount("MaxLayerCount",int) = 20

        [Header(Shadow)]
        _MinSelfShadowLayerCount("MinSelfShadowLayerCount",int) = 5
        _MaxSelfShadowLayerCount("MaxSelfShadowLayerCount",int) = 10
        _ShadowIntensity("ShadowIntensity" , float) = 1
        [Toggle(_SOFTSHADOW_ON)]_SoftShadow("SoftShadow",float) = 1


    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}
        LOD 100

        pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature _SOFTSHADOW_ON 

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
                float3 normalWS     : TEXCOORD1;
                float3 tangentWS    : TEXCOORD2;
                float3 bitangentWS  : TEXCOORD3;
                float3 viewWS       : TEXCOORD4;
                float3 viewTS       : TEXCOORD5;
                float3 lightTS      : TEXCOORD6;
            };
            
            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D(_NormalMap);SAMPLER(sampler_NormalMap);
            TEXTURE2D(_ParallaxMap);SAMPLER(sampler_ParallaxMap);

            //CBuffer部分，数据参数定义在该结构内，可以使用srp的batch功能
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
                float4 _SpecularColor;
                float  _SpecularPow;
                float4 _NormalMap_ST;
                float  _NormalScale;
                float4 _ParallaxMap_ST;
                float  _ParallaxScale;
                float  _MinLayerCount;
                float  _MaxLayerCount;
                float  _MinSelfShadowLayerCount;
                float  _MaxSelfShadowLayerCount;
                float  _ShadowIntensity;
            CBUFFER_END

            half GetParallaxMappingHeight(half2 uv)
            {
                //参考ParallaxMapping.hlsl
                half lod = 0;
                half HeightMap = SAMPLE_TEXTURE2D_LOD(_ParallaxMap , sampler_ParallaxMap , uv , lod).r;
                return HeightMap;
            }

            //浮雕映射
            half2 RelievoParallaxMapping(half2 uv, int minNumLayer , int maxNumLayer , half amplitude, half3 viewDirTS , out half outLayerHeight)
            {
                //高度图的整体范围是在[0-1],
                viewDirTS = normalize(viewDirTS);
                outLayerHeight = 0;
                //因为在TBN空间，视角越接近(0,0,1)也就是法线，需要采样的次数越少
                half numLayers = lerp((half)maxNumLayer,(half)minNumLayer,abs(dot(half3(0.0, 0.0, 1.0), viewDirTS)));
                //这个部分和SteepParallaxMapping上面的一模一样（为了方便阅读我直接复制粘贴，没有用函数包装）

                //NumLayers表示一共分多少层采样，stepSize 每层的间隔
                half stepSize = 1.0 / numLayers;
                //这一步和简单的视差映射一样，但是我们想要从视角往下找,视角向量是一个指向视点的向量，我们想要从视点开始找
                //所以这里除以的-z，但是无所谓反正把视角向量反过来就行
                half2 parallaxMaxOffsetTS = (viewDirTS.xy / -viewDirTS.z)* amplitude;
                //求出每一层的偏移，然后我们要逐层判断
                half2 uvOffsetPerStep = stepSize * parallaxMaxOffsetTS;

                //初始化当前偏移
                half2 uvOffsetCurrent = uv;
                //GetParallaxMapHeight是自定义函数就在该文件的上面
                half preMapHeight = GetParallaxMappingHeight(uvOffsetCurrent);
                uvOffsetCurrent += uvOffsetPerStep;
                half currMapHeight = GetParallaxMappingHeight(uvOffsetCurrent);
                half layerHeight = 1 - stepSize; 

                //遍历所有层查找估计偏差点（采样高度图得到的uv点的高度 > 层高的点）
                //unable to unroll loop, loop does not appear to terminate in a timely manner
                //上面这个错误是在循环内使用tex2D导致的，需要加上unroll来限制循环次数或者改用tex2Dlod
                for (int stepIndex = 0; stepIndex < numLayers; ++stepIndex)
                {
                    //我们找到了估计偏差点
                    if (currMapHeight > layerHeight)
                    break;

                    preMapHeight = currMapHeight;
                    layerHeight -= stepSize;
                    uvOffsetCurrent += uvOffsetPerStep;

                    currMapHeight = GetParallaxMappingHeight(uvOffsetCurrent);
                }

                //一般来说这里应该指定一个查询次数,用二分法查询，但是后来出现了割线法，可以更加快速近似
                half pt0 = layerHeight + stepSize;
                half pt1 = layerHeight;
                half delta0 = pt0 - preMapHeight;
                half delta1 = pt1 - currMapHeight;

                half delta;
                half2 finalOffset;


                // Secant method to affine the search
                // Ref: Faster Relief Mapping Using the Secant Method - Eric Risser
                // Secant Method - Eric Risser，割线法
                for (int i = 0; i < 3; ++i)
                {
                    // intersectionHeight is the height [0..1] for the intersection between view ray and heightfield line
                    half intersectionHeight = (pt0 * delta1 - pt1 * delta0) / (delta1 - delta0);
                    outLayerHeight = intersectionHeight;
                    // Retrieve offset require to find this intersectionHeight
                    finalOffset = (1 - intersectionHeight) * uvOffsetPerStep * numLayers;

                    currMapHeight = GetParallaxMappingHeight(uv + finalOffset);

                    delta = intersectionHeight - currMapHeight;

                    if (abs(delta) <= 0.01)
                    break;

                    // intersectionHeight < currHeight => new lower bounds
                    if (delta < 0.0)
                    {
                        delta1 = delta;
                        pt1 = intersectionHeight;
                    }
                    else
                    {
                        delta0 = delta;
                        pt0 = intersectionHeight;
                    }
                }
                
                return uv + finalOffset;
            }

            half ParallaxSelfShadowing(half2 uv , half layerHeight , int minNumLayers , int maxNumLayers , half amplitude , half3 lightDirTS)
            {
                lightDirTS = normalize(lightDirTS);
                //如果没有点被遮挡的时候shadowMutiplier应该是1
                half shadowMultiplier =1;
                if(dot(half3(0,0,1) , lightDirTS) > 0)
                {
                    half numSamplesUnderSurface = 0;

                    #if defined(_SOFTSHADOW_ON)
                        //因为软阴影下面要取最大值所以设置为0
                        shadowMultiplier = 0;
                    #endif

                    //因为在TBN空间，光线越接近(0,0,1)也就是法线，需要判断的次数也越少
                    half numLayers = lerp((half)maxNumLayers,(half)minNumLayers,abs(dot(half3(0.0, 0.0, 1.0), lightDirTS)));

                    //高度图整体范围 [0,1],numLayers 表示分了多少层,stepSize 每层的间隔,重新分层是从视差映射得到的结果开始分层，所以这里不是1/numLayers，而我是当作高度图，所以用1减去
                    half stepSize = (1 - layerHeight) / numLayers;
                    //因为我们要找被多少层挡住了，所以直接延光源方向找，所以不需要除-z（不需要反转光源方向）
                    half2 parallaxMaxOffsetTS = (lightDirTS.xy / lightDirTS.z)* amplitude;
                    //求出每一层的偏移，然后我们要逐层判断
                    half2 uvOffsetPerStep = stepSize * parallaxMaxOffsetTS;

                    //初始化当前偏移
                    half2 uvOffsetCurrent = uv + uvOffsetPerStep;
                    //GetParallaxMapHeight是自定义函数就在该文件的上面
                    half currMapHeight = GetParallaxMappingHeight(uvOffsetCurrent);
                    half currLayerHeight = layerHeight + stepSize;

                    #if defined(_SOFTSHADOW_ON)
                        int shadowStepIndex = 1;
                    #endif

                    //unable to unroll loop, loop does not appear to terminate in a timely manner
                    //上面这个错误是在循环内使用tex2D导致的，需要加上unroll来限制循环次数或者改用tex2Dlod
                    for (int stepIndex = 0; stepIndex < numLayers; ++stepIndex)
                    {
                        if (currLayerHeight >0.99)
                        break;

                        if(currMapHeight > currLayerHeight)
                        {
                            //防止在0到1范围外的影子出现，如果不处理当影子较长时边缘会有多余的影子
                            if(uvOffsetCurrent.x >= 0 && uvOffsetCurrent.x <= 1.0 && uvOffsetCurrent.y >= 0 &&uvOffsetCurrent.y <= 1.0)
                            {
                                numSamplesUnderSurface += 1; //被遮挡的层数
                                #if defined(_SOFTSHADOW_ON) 
                                    //想象一下软阴影的特征，越靠近边缘，影子越浅
                                    half newShadowMultiplier = (currMapHeight - currLayerHeight) * (1 - shadowStepIndex / numLayers);
                                    shadowMultiplier = max(shadowMultiplier, newShadowMultiplier);
                                #endif
                            }
                        }

                        #if defined(_SOFTSHADOW_ON)
                            shadowStepIndex += 1;
                        #endif

                        currLayerHeight += stepSize;
                        uvOffsetCurrent += uvOffsetPerStep;

                        currMapHeight = GetParallaxMappingHeight(uvOffsetCurrent);
                    }
                    #if defined(_SOFTSHADOW_ON)
                        shadowMultiplier = numSamplesUnderSurface < 1 ? 1.0 :(1 - shadowMultiplier);
                    #else
                        shadowMultiplier = 1 - numSamplesUnderSurface / numLayers; //根据被遮挡的层数来决定阴影深浅
                    #endif

                    
                }
                return shadowMultiplier;
                
            }

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                //获取世界空间下的法线相关的数据，用于构建TBN矩阵
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.tangentWS = real3(TransformObjectToWorldDir(v.tangentOS.xyz));
                real sign = real(v.tangentOS.w) * GetOddNegativeScale();
                o.bitangentWS = cross(o.normalWS , o.tangentWS) * sign;

                //世界空间下的视口方向
                o.viewWS = GetWorldSpaceViewDir(positionWS);
                //计算切线空间下的视口方向,参考ParallaxMapping.hlsl中的GetViewDirectionTangentSpace()方法
                half3x3  tangentSpaceTransform = float3x3(o.tangentWS.xyz , o.bitangentWS.xyz , o.normalWS.xyz);
                o.viewTS = mul(tangentSpaceTransform, o.viewWS);

                Light light = GetMainLight();
                o.lightTS = mul(tangentSpaceTransform , light.direction);

                o.uv = TRANSFORM_TEX(v.texcoord , _BaseMap);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;

                half outLayerHeight;
                half2 finalUV = RelievoParallaxMapping(i.uv , _MinLayerCount , _MaxLayerCount , _ParallaxScale , i.viewTS , outLayerHeight);

                //裁剪掉周围的东西，因为图片如果设置的Wrap Mode设置的是Repeat(重复模式)，则会在边缘看到重复的平铺图像
                if(finalUV.x > 1.0 || finalUV.y > 1.0 || finalUV.x < 0.0 || finalUV.y < 0.0)
                discard;

                half shadowMultiplier = ParallaxSelfShadowing(finalUV , outLayerHeight ,_MinSelfShadowLayerCount , _MaxSelfShadowLayerCount , _ParallaxScale ,i.lightTS);
                
                //光照
                Light light = GetMainLight();
                half3 lightColor = light.color * light.distanceAttenuation;
                half3 lightDir = light.direction;

                //基础颜色贴图
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap , finalUV);

                //法线贴图
                half4 normalTexture = SAMPLE_TEXTURE2D(_NormalMap , sampler_NormalMap , finalUV);
                half3 normalTS = UnpackNormalScale(normalTexture , _NormalScale);
                half3 normalWS = TransformWorldToTangentDir(normalTS , float3x3(i.tangentWS.xyz , i.bitangentWS.xyz , i.normalWS.xyz));
                normalWS = normalize(normalWS);
                half3 viewWS = SafeNormalize(i.viewWS);

                half3 ambientColor = unity_AmbientSky.rgb * baseMap.rgb;
                half3 diffuseColor = lightColor * baseMap.rgb * _BaseColor.rgb * saturate(dot(normalWS , lightDir));
                half3 specularColor = LightingSpecular(lightColor , lightDir , normalWS , viewWS , _SpecularColor , _SpecularPow);

                FinalColor = half4(ambientColor + (diffuseColor + specularColor) * pow(abs(shadowMultiplier),_ShadowIntensity) , 1);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
