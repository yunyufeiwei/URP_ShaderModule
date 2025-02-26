Shader "Art_URP/ExampleShow/Growth"
{
    Properties
    {
        [Header(BaseMap)]
        _Color("Color",Color) = (1,1,1,1)
        _BaseMap("BaseMap" , 2D) = "white"{}
        _BaseMapBrightness("BaseMapBrightness" , float) = 1

        [Header(NormalMap)]
        _NormalMap("NormalMap",2D) = "bump"{}
        _NormalScale("NormalScale" , float) = 1

        [Header(Growth)]
        _GrowthValue("GrowthValue",Range(-1.5,1)) = 0   //如果收缩范围有问题，导致clip范围不对，可能是这里的最小值设置不对，需要设置为负数才行
        _MinGrowth("MinGrowth",float) = 0
        _MaxGrowth("MaxGrowth",float) = 1

        _EndMin("End Min",Range(0.0,1.0)) = 0.5
        _EndMax("End Max",Range(0.0,1.5)) = 1.0
        _Expand("Expand(扩大)",float) = 0
        _VertexScale("VertexScale",float) = 1
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry"}

        LOD 100

        pass
        {
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
                float3 positionWS   : TEXCOORD;
                float2 uv           : TEXCOORD1;
                float3 normalWS     : TEXCOORD2;
                float3 tangentWS    : TEXCOORD3;
                float3 bitangentWS  : TEXCOORD4;
            };
            
            //属性定义部分
            //定义纹理采样贴图和采样状态
            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D(_NormalMap);SAMPLER(sampler_NormalMap);

            //CBuffer部分，数据参数定义在该结构内，可以使用srp的batch功能
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _BaseMap_ST;
                float  _BaseMapBrightness;
                float4 _NormalMap_ST;
                float  _NormalScale;
                float  _GrowthValue;
                float  _MinGrowth;
                float  _MaxGrowth;
                float  _EndMin;
                float  _EndMax;
                float  _Expand;
                float  _VertexScale;
                float  _CutOff;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                
                //使用uv计算方向遮罩，获取y方向遮罩.OpenGL下，Y方向的颜色是从下面（黑色）到上面（白色）
                //growthMask用来限制顶点收缩，制作藤蔓的尖尖部分，其中_MinGrowth ， _MaxGrowth用来控制收紧范围,这里得到得结果尖尖部分是白色
                half growthMask = smoothstep(_MinGrowth , _MaxGrowth , (v.texcoord.y - _GrowthValue));
                half weight_End = smoothstep(_EndMin , _EndMax , v.texcoord.y);
                half combinedMask = max(growthMask , weight_End);

                //动画效果是在顶点上计算，因此处于渲染管线的第一阶段
                half3 vertexOffset = v.normalOS.xyz * _VertexScale * combinedMask * 0.01f;
                half3 vertexScale = v.normalOS.xyz * _Expand * 0.01f;
                half3 finalVertexOffset = vertexOffset + vertexScale;
                v.positionOS.xyz += finalVertexOffset;

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);

                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);
                half signDir = real(v.tangentOS.w) * GetOddNegativeScale();
                o.bitangentWS =cross(o.normalWS , o.tangentWS) * signDir;

                o.uv = v.texcoord;

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;

                Light light = GetMainLight();
                half4 lightColor = half4(light.color * light.distanceAttenuation , 1);
                half3 lightDir = light.direction;

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap , i.uv);

                //UnpackNormal
                //提取法线贴图，通过TBN矩阵将贴图的法线从切线空间转换到世界空间
                half4 bumpMap = SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap , i.uv);
                half3 normalTS = UnpackNormalScale(bumpMap , _NormalScale);
                half3 worldNormalWS = normalize(TransformTangentToWorld(normalTS , float3x3(i.tangentWS.xyz , i.bitangentWS.xyz , i.normalWS.xyz)));

                //LightModel
                half halfLambert = saturate(dot(lightDir , worldNormalWS)) * 0.5 + 0.5; 

                half4 ambientColor = _GlossyEnvironmentColor * baseMap;

                half4 diffuse = halfLambert * baseMap * _BaseMapBrightness;
                
                //裁剪部分
                clip(1 - (i.uv.y - _GrowthValue));

                FinalColor = ambientColor + diffuse;

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
