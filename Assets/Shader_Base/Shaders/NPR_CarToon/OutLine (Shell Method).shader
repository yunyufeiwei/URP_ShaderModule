//背面法线扩张也叫Shell Method 或 Back Facing
//这个目前也是常用的描边办法
//该方法原理不再像Z-Bias，直接在观察空间平移
//该方法通过使顶点沿法线方向平移来达到描边的效果

//该方式等于是又将物体画了一遍，所以我们有2个Pass，第1个Pass正常画，第2个Pass是轮廓
//轮廓只画背面，所以需要Cull Front
//该方式本身并不复杂，但是这是个常用的东西，所以写的相对完善了一些
//提供一种普通的按距离位移，另一种是按像素位移并且等宽的描边
//因为沿法线位移对于硬边来说，硬边的法线不是平滑的，所以沿法线移动后会分离，所以我提供了一个简单的法线平滑工具 Tools -> OutlineSmoothNormalsTool

//参考资料：
//https://alexanderameye.github.io/notes/rendering-outlines/
//https://www.videopoetics.com/tutorials/pixel-perfect-outline-shaders-unity/#working-in-clip-space

Shader "Art_URP/Base/NPR/OutLine (Shell Method)"
{
    Properties
    {
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _OutlineWidth ("Outline Width",Float) = 0.5
        [Toggle] _PixelWidth("Pixel Width",Float) = 0

        //枚举 [KeywordEnum]如何使用 看官方文档 https://docs.unity3d.com/ScriptReference/MaterialPropertyDrawer.html
        [KeywordEnum(None,Color,Tangent,UV3)] _SmoothedNormalData("Use Smoothed Normal Data",Float) = 0
        [KeywordEnum(None,Compress,TBN)] _CompressMethod ("Compress Method In UV Data",Float) = 0
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
                float4 positionOS   : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
            };

            Varyings vert(Attributes v)
            {
                Varyings o;

                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformWorldToHClip(positionWS);
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                return half4(1,1,1,1);
            }

            ENDHLSL
        }

        pass
        {
            //Tags{"LightMode" = "Outline"}
            Tags{"LightMode" = "SRPDefaultUnlit"}
            Cull Front

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //关于[Toggle] [ToggleOff] [KeywordEnum]如何使用 看官方文档 https://docs.unity3d.com/ScriptReference/MaterialPropertyDrawer.html
            #pragma shader_feature __ _PIXELWIDTH_ON 
            #pragma shader_feature _SMOOTHEDNORMALDATA_NONE _SMOOTHEDNORMALDATA_COLOR _SMOOTHEDNORMALDATA_TANGENT _SMOOTHEDNORMALDATA_UV3
            #pragma shader_feature _COMPRESSMETHOD_NONE _COMPRESSMETHOD_COMPRESS _COMPRESSMETHOD_TBN 

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS      : NORMAL;
                float4 tangentOS     : TANGENT;
                #ifdef _SMOOTHEDNORMALDATA_UV3
                    float2 uv3 : TEXCOORD2;
                #elif _SMOOTHEDNORMALDATA_COLOR
                    float4 color : COLOR;
                #endif
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _OutlineColor;
                half _OutlineWidth;
            CBUFFER_END

            //获取世界空间下的法线
            float3 GetWorldSpaceNormal(Attributes IN)
            {
                float3 normalWS = 0;
                //如果平滑后的法线数据被存在UV3中，UV1/UV2一般都会被其他功能占用，所以建议UV3开始
                #ifdef _SMOOTHEDNORMALDATA_UV3
                    //使用压缩数据，这里的数据是通过平滑工具将法线的3个float压成2个float并存入UV3，下面是解码，具体压缩看OutlineSmoothNormalsToolEditor.cs
                    //注：不用非常纠结这是个什么算法，等同于x=0.1 y=0.2 z=0.3 ，然后拼接在一起等于uv3.x = 0.1 + 0.002 = 0.102(2个float转1个)，uv.y = z，解的时候反过来
                    #ifdef _COMPRESSMETHOD_COMPRESS
                        float2 compressedData = IN.uv3.xy;
                        float2 decodeMul = float2(1.0,65025.0);
                        float decodeBit = 1.0/65025.0;
                        float2 unpack = compressedData.x * decodeMul;
                        unpack = frac(unpack);
                        unpack.x -= unpack.y * decodeBit;
                        float3 decode = float3(unpack.xy,compressedData.y);
                        normalWS = decode * 2 - 1;
                        //使用压缩数据，这里的数据是通过平滑工具将法线的3个float转换到TBN空间，下面是解码，这个和法线从TBN解码过来一摸一样，具体压缩看OutlineSmoothNormalsToolEditor.cs
                    #elif _COMPRESSMETHOD_TBN 
                        float3 normalTS = 0;
                        normalTS.xy = IN.uv3.xy;
                        normalTS.z =  max(1.0e-16, sqrt(1.0 - saturate(dot(normalTS.xy, normalTS.xy))));
                        VertexNormalInputs normalInput = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);
                        float3x3 TBNWorld = float3x3(normalInput.tangentWS.xyz, normalInput.bitangentWS.xyz, normalInput.normalWS.xyz);
                        normalWS = TransformTangentToWorld(normalTS,TBNWorld);
                    #endif
                    //平滑后的顶点法线数据直接写入顶点色
                #elif _SMOOTHEDNORMALDATA_COLOR
                    normalWS = TransformObjectToWorldNormal(IN.color.xyz);
                    //平滑后的顶点法线数据直接写入顶点切线数据
                #elif _SMOOTHEDNORMALDATA_TANGENT
                    normalWS = TransformObjectToWorldNormal(IN.tangentOS.xyz);
                    //使用模型原始法线
                #else
                    normalWS = TransformObjectToWorldNormal(IN.normalOS);
                #endif
                
                return normalWS;
            }

            Varyings vert(Attributes v)
            {
                Varyings o;

                //方案一：直接沿法线方向放大，该方案直接导致整个面都向外扩展了
                // half3 ScalePositionOS = v.positionOS.xyz + normalize(v.normalOS.xyz) * _OutlineWidth;
                // o.positionHCS = TransformObjectToHClip(ScalePositionOS);

                //方案二：
                //【B】转换到观察空间，对于内凹的模型（例如：环体Torus），可能发生背面面片遮挡住正面面片的情况，所以让顶点法线的z分量等于一个恒定的值
                //然后归一化并座位扩张用的向量，扩张后的背面更加扁平，降低遮挡正面面片的可能性
                //float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                //float3 positionVS = TransformWorldToView(positionWS);
                //float3 normalVS = TransformWorldToViewDir(TransformObjectToWorldNormal(IN.normalOS));
                //恒定z值，可以把这个值改成变量，然后用Torus（在工程里面搜我准备好了）试一下
                //normalVS.z = -0.4;
                //positionVS += normalize(normalVS) * _OutlineWidth * 0.1;
                //OUT.positionHCS = TransformWViewToHClip(positionVS);


                half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);

                #ifdef _PIXELWIDTH_ON
                    //我们在裁剪空间下来计算描边，想要用像素描述，本质上要在屏幕空间下，在顶点着色器中最接近的就是裁剪空间
                    float3 normalWS = GetWorldSpaceNormal(v);
                    float3 normalHCS = mul((float3x3)UNITY_MATRIX_VP, normalWS);
                    o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);

                    //顶点着色器的输出就是裁剪空间下的坐标，后续要转NDC空间和屏幕空间
                    //因为后续会转换成NDC坐标（裁剪空间经过透视除法后到NDC空间）会除w，所以我们先乘一个w来抵消透视
                    //匹配屏幕比例，所以除以_ScreenParams.xy
                    //NDC下的xy的范围都是[-1,1]，范围是2，如果我们想要_OutlineWidth = 1时，表示1像素，我们需要将屏幕宽度和高度除以2
                    //因为屏幕的范围是[0,1]，所以最后NDC空间经过视口变换(view port)到屏幕坐标的时候需要将NDC坐标的(xy + 1) * 0.5
                    //可能写成(_OutlineWidth * o.positionHCS.w) / _ScreenParams.xy * 2.0;更好理解一些
                    float2 outlineOffset =  (_OutlineWidth * o.positionHCS.w) / (_ScreenParams.xy / 2.0);
                //直接拿xy偏移，在裁剪空间中，我们的位置X和Y是应于顶点在屏幕上的水平和垂直位置，所以我们不需要z了
                    o.positionHCS.xy += normalize(normalHCS.xy) * outlineOffset;
                //常规模式，单位就是距离，会有近大远小，做法和【B】一样
                #else
                    float3 positionVS = TransformWorldToView(positionWS);
                    float3 normalWS = GetWorldSpaceNormal(v);
                    float3 normalVS = TransformWorldToViewDir(normalWS);
                    //恒定z值，可以把这个值改成变量，然后用Torus（在工程里面搜我准备好了）试一下
                    normalVS.z = -0.4;
                    positionVS += normalize(normalVS) * _OutlineWidth;
                    o.positionHCS = TransformWViewToHClip(positionVS);
                #endif

                return o;

            }
            
            half4 frag(Varyings i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDHLSL

        }
    }
}
