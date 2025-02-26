//高度图或者说视差映射，法线贴图主要的目的是描述物体的光照，视差贴图主要描述的是物体的遮挡情况，可以使物体表面的凹凸和光照更加真实，特别在视角与法线夹角变大时
//简单的视差映射 Parallax Mapping（效果不好，但是计算超级简单，如果你只想要有那么一点点效果可以用这个）
//陡峭视差映射 Steep Parallax Mapping (raymarch思想的步进法线性查找，不常用，因为下面2个都是对这个方法的优化)
//视差遮蔽映射 Parallax Occlusion Mapping (简称：POM)(这个比较常用是对陡峭视差的优化实现，本质上之比陡峭视差多了一步插值)
//浮雕映射 Relief Parallax Mapping（这个比较常用是对陡峭视差的优化实现，本质上只比陡峭视差多了一步二分查找或者割线法查找）
//浮雕映射比视差遮蔽映射多了额外的二分查找，所以和其一样的线性插值部分步进数量可以小一些来节省开销。而二分查找提高精确度，所以理论上比视差遮蔽映射更好，但是开销更大
//浮雕映射后来出现了割线法，割线法有着比二分查找更快的收敛速度，即使用非常少查找次数，就可以得到很好的精度，虽然还是比视差遮蔽映射稍微费一点（该文件使用割线法而不是二分查找）

//https://zhuanlan.zhihu.com/p/319769756
//https://learnopengl-cn.github.io/05%20Advanced%20Lighting/05%20Parallax%20Mapping/
//https://www.gamedev.net/articles/programming/graphics/a-closer-look-at-parallax-occlusion-mapping-r3262/
//https://zhuanlan.zhihu.com/p/412555049
//http://ma-yidong.com/2019/06/22/a-short-history-of-parallax-occlusion-mapping-relief-mapping/

//视差背后的思想是修改纹理坐标，使一个fragment的表面看起来比实际的更高或者更低，所有这些都根据观察方向和高度贴图。

Shader "Art_URP/Base/Light/HeightMap-ParallaxMapping"
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
        _NormalTexture("NormalTexture" , 2D) = "white"{}
        _NormalScale("NormalScale" , float) = 1

        [Header(Parallax)]
        _ParallaxMap("HeightMap" , 2D) = "white"{}
        _ParallaxScale("ParallaxScale" , float) = 0.01
        _MinLayerCount("MinLayerCount" , int) = 5
        _MaxLayerCount("MaxLayerCount" , int) = 20
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

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS     : POSITION;
                float2 texcoord       : TEXCOORD;
                float3 normalOS       : NORMAL;
                float4 tangentOS      : TANGENT;
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
            };
            
            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D(_NormalTexture);SAMPLER(sampler_NormalTexture);
            TEXTURE2D(_ParallaxMap);SAMPLER(sampler_ParallaxMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
                float4 _SpecularColor;
                float  _SpecularPow;
                float4 _NormalTexture_ST;
                float  _NormalScale;
                float4 _ParallaxMap_ST;
                float  _ParallaxScale;
                float  _MinLayerCount;
                float  _MaxLayerCount;
            CBUFFER_END

            //采样视差贴图
            half GetParallaxMappingHeight(half2 uv)
            {
                //参考ParallaxMapping.hlsl
                half lod = 0;
                half HeightMap = SAMPLE_TEXTURE2D_LOD(_ParallaxMap , sampler_ParallaxMap , uv , lod).r;
                return HeightMap;
            }

            //简单的视差映射，使用Unity RUP中的计算方式，参考了ParallaxMapping.hlsl中的ParallaxOffset1Step()函数
            half2 URPParallaxMapping(half2 uv, half amplitude, half3 viewDirTS)
            {
                half height = GetParallaxMappingHeight(uv);
                height = height * amplitude - amplitude / 2.0;
                half3 v = normalize(viewDirTS);
                v.z += 0.42;
                half2 uvOffset = height * (v.xy / v.z);
                return uv + uvOffset;
            }

            //简单视差映射ParallaxMapping
            //简单视差映射并不会消耗太多的性能，但效果要大打折扣
            //当高度较为陡峭视角与表面角度较大时，会出现明显走样
            half2 ParallaxMapping(half2 uv , half amplitude , half3 viewDirTS)
            {
                half height = GetParallaxMappingHeight(uv);
                half3 viewDir = normalize(viewDirTS);
                //这里v.xy/v.z,并不是一定要除z。想象一下在TBN空间下，z越大视角越接近法线，所需要的偏移越小，如果视角与法线平行说明可以指直接看到，不需要偏移了;
                //同样的当视角与法线接近垂直的时候，z接近无限小,从而增加纹理坐标的偏移；这样做在视角上会获得更大的真实度。
                //但也会因为在某些角度看会不好看所以也可以不除z，不除z的技术叫做 Parallax Mapping with Offset Limiting（有偏移量限制的视差贴图）
                half2 uvOffset = viewDir.xy / viewDir.z * (height * amplitude);
                return uv + uvOffset;
            }

            //陡峭视差映射 Steep Parallax Mapping
            //Library\PackageCache\com.unity.render-pipelines.core@14.0.8\ShaderLibrary\PerPixelDisplacement.hlsl中的复杂视差算法
            //使用raymarch也就是步进采样法，从摄像机开始往下找，也就是从上往下找，因为上面简单的视差是直接近似，所以在高度陡峭变化的情况下效果不好，寻找最近的位置，而不是直接使用近似值
            //提交采样数量提高精确性，但层数越多越准确，性能消耗也越大
            half2 SteepParallaxMapping(half2 uv , int numLayers , half amplitude , half3 viewDirTS)
            {
                //高度图的整体范围是在[0-1],NumLayers表示一共分多少层采样，stepSize表示每一层采样之间的间隔
                viewDirTS = normalize(viewDirTS);
                half stepSize = 1.0 / (half)numLayers;
                
                //这一步和简单的视差映射一样，但是我们想要从视角往下找,视角向量是一个指向视点的向量，我们想要从视点开始找
                //所以这里除以的-z，但是无所谓反正把视角向量反过来就行
                half2 parallaxMaxOffsetTS = (viewDirTS.xy / -viewDirTS.z) * amplitude;
                //求出每一层的偏移，然后我们要逐层判断
                half2 uvOffsetPerStep = stepSize * parallaxMaxOffsetTS;

                //初始化当前偏移，也就是最开始输入的uv
                half2 uvOffsetCurrent = uv;
                //使用定义的方法采样高度图
                half perMapHeight = GetParallaxMappingHeight(uvOffsetCurrent);
                //将当前的uv偏移与采样纹理的值进行相加后得到最新的当前uv
                uvOffsetCurrent += uvOffsetPerStep;
                //在采样当前偏移之后的uv
                half currMapHeight = GetParallaxMappingHeight(uvOffsetCurrent);
                half layerHeight = 1 - stepSize;

                for(int stepIndex = 0; stepIndex < numLayers; ++stepIndex)
                {
                    if(currMapHeight > layerHeight)
                    break;
                    perMapHeight = currMapHeight;
                    layerHeight -= stepSize;
                    uvOffsetCurrent += uvOffsetPerStep;

                    currMapHeight = GetParallaxMappingHeight(uvOffsetCurrent);
                }
                return uvOffsetCurrent;
            }

            //视差遮蔽映射 Parallax Occlusion Mapping (POM)
            //在URP的Library\PackageCache\com.unity.render-pipelines.core@14.0.8\ShaderLibrary\PerPixelDisplacement.hlsl找到了相关实现
            //你会发现陡峭视差映射，其实也有问题，结果不应该直接就用找到的估计偏差点
            //因为我们知道准确的偏移在 估计偏差点和估计偏差点的前一个点之间
            //可以插值这2个点来得到更好的结果
            half2 ParallaxOcclusionMapping(half2 uv , int minNumLayer , int maxNumLayer , half amplitude , half3 viewDirTS)
            {
                viewDirTS = normalize(viewDirTS);
                //因为在TBN空间，视角越接近（0,0,1）也就是法线，需要采样的次数越少
                half numLayers = lerp((half)maxNumLayer , (half)maxNumLayer , abs(dot(half3(0.0,0.0,1.0) , viewDirTS)));
                //stepSize表示每一层采样之间的间隔
                half stepSize = 1.0 / (half)numLayers;
                
                //这一步和简单的视差映射一样，但是我们想要从视角往下找,视角向量是一个指向视点的向量，我们想要从视点开始找
                //所以这里除以的-z，但是无所谓反正把视角向量反过来就行
                half2 parallaxMaxOffsetTS = (viewDirTS.xy / -viewDirTS.z) * amplitude;
                //求出每一层的偏移，然后我们要逐层判断
                half2 uvOffsetPerStep = stepSize * parallaxMaxOffsetTS;

                //初始化当前偏移，也就是最开始输入的uv
                half2 uvOffsetCurrent = uv;
                //使用定义的方法采样高度图
                half perMapHeight = GetParallaxMappingHeight(uvOffsetCurrent);
                //将当前的uv偏移与采样纹理的值进行相加后得到最新的当前uv
                uvOffsetCurrent += uvOffsetPerStep;
                //在采样当前偏移之后的uv
                half currMapHeight = GetParallaxMappingHeight(uvOffsetCurrent);
                half layerHeight = 1 - stepSize;

                for(int stepIndex = 0; stepIndex < numLayers; ++stepIndex)
                {
                    if(currMapHeight > layerHeight)
                    break;
                    perMapHeight     = currMapHeight;
                    layerHeight     -= stepSize;
                    uvOffsetCurrent += uvOffsetPerStep;

                    currMapHeight = GetParallaxMappingHeight(uvOffsetCurrent);
                }

                //插值计算
                half delta0 = currMapHeight - layerHeight;
                half delta1 = (layerHeight + stepSize) - perMapHeight;
                half ratio = delta0 / (delta0 + delta1);
                //这里就是比较常见的插值写法。
                //uvOffsetCurrent - uvOffsetPerStep 表示上一步的偏移
                //half2 finalOffset = (uvOffsetCurrent - uvOffsetPerStep) * ratio + uvOffsetCurrent * (1 - ratio);
                //这里是URP里面的写法（算是一个小优化，其实就是化简上面这个式子）
                half2 finalOffset = uvOffsetCurrent - ratio * uvOffsetPerStep;

                return finalOffset;
            }

            half2 RelievoParallaxMapping(half2 uv, int minNumLayer , int maxNumLayer , half amplitude, half3 viewDirTS)
            {
                //高度图的整体范围是在[0-1],
                viewDirTS = normalize(viewDirTS);
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

                o.uv = TRANSFORM_TEX(v.texcoord , _NormalTexture);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;

                //视差贴图处理
                //方案一：
                //URP的几个标准shader，建议第2个参数_ParallaxScale的值是[0.005,0.08]
                //当_ParallaxScale的参数值越大，会出现割裂的效果
                // half2 finalUV = URPParallaxMapping(i.uv , _ParallaxScale , i.viewTS);  
                
                //方案二：
                // half2 finalUV = ParallaxMapping(i.uv , _ParallaxScale ,i.viewTS);

                //方案三：
                // half2 finalUV = SteepParallaxMapping(i.uv , _MinLayerCount , _ParallaxScale , i.viewTS);

                //方案四：
                // half2 finalUV = ParallaxOcclusionMapping(i.uv , _MinLayerCount , _MaxLayerCount , _ParallaxScale , i.viewTS);

                //方案五：
                half2 finalUV = RelievoParallaxMapping(i.uv , _MinLayerCount , _MaxLayerCount , _ParallaxScale , i.viewTS);

                //裁剪掉周围的东西，因为图片如果设置的Wrap Mode设置的是Repeat(重复模式)，则会在边缘看到重复的平铺图像
                if(finalUV.x > 1.0 || finalUV.y > 1.0 || finalUV.x < 0.0 || finalUV.y < 0.0)
                discard;

                //光照
                Light light = GetMainLight();
                half3 lightColor = light.color * light.distanceAttenuation;
                half3 lightDir = light.direction;

                //基础颜色贴图
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap , finalUV);

                //法线贴图
                half4 normalTexture = SAMPLE_TEXTURE2D(_NormalTexture , sampler_NormalTexture , finalUV);
                half3 normalTS = UnpackNormalScale(normalTexture , _NormalScale);
                half3 normalWS = TransformWorldToTangentDir(normalTS , float3x3(i.tangentWS.xyz , i.bitangentWS.xyz , i.normalWS.xyz));
                normalWS = normalize(normalWS);
                half3 viewWS = SafeNormalize(i.viewWS);

                half3 ambientColor = unity_AmbientSky.rgb * baseMap.rgb;
                half3 diffuseColor = lightColor * baseMap.rgb * _BaseColor.rgb * saturate(dot(normalWS , lightDir));
                half3 specularColor = LightingSpecular(lightColor , lightDir , normalWS , viewWS , _SpecularColor , _SpecularPow);

                FinalColor = half4(ambientColor + diffuseColor + specularColor , 1);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
