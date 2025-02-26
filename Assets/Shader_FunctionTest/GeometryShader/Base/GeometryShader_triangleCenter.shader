Shader "Art_URP/FunctionTest/GeometryShader_TriangleCenter"
{
    Properties
    {
        _Color("Color" , Color) = (1,1,1,1)
        [PowerSlider(3.0)]_Length("Length",Range(0,20)) = 1
        [PowerSlider(3.0)]_Power("Power",Range(0,20)) = 1
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
            //声明一个集几何色器
            #pragma geometry geom
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            //
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD;
            };

            //顶点向集合阶段传递数据
            struct Vert2Geom
            {
                float4 positionGS   : SV_POSITION;
                float2 uv_GS        : TEXCOORD0;
                float3 pos          : TEXCOORD1;
            };

            //几何向片元阶段传递数据
            struct Geom2Frag
            {
                float4 positionHCS : SV_POSITION; 
                float2 uv : TEXCOORD0; 
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float  _Length;
                float _Power;
            CBUFFER_END

            Vert2Geom vert (Attributes v)
            {
                Vert2Geom o = (Vert2Geom) 0;

                o.positionGS = TransformObjectToHClip(v.positionOS.xyz);
                o.pos = v.positionOS.xyz;
                
                o.uv_GS = v.texcoord;
                return o;
            }

            float rand(float2 p)
            {
                return frac(sin(dot(p ,float2(12.9898,78.233))) * 43758.5453);
            }

            //静态制定单个调用的最大顶点个数 
            // [NVIDIA08]指出，当GS输出在1到20个标量之间时，可以实现GS的性能峰值，如果GS输出在27-40个标量之间，则性能下降50％。
            [maxvertexcount(20)]

            //三角形显示模式
            void geom(triangle Vert2Geom input[3] , inout TriangleStream<Geom2Frag> outStream)
            {
                Geom2Frag o = (Geom2Frag)0;
                
                //-----------这里通过三角面的两个边叉乘来获得垂直于三角面的法线方向 
                float3 v1 = (input[1].pos - input[0].pos).xyz; 
                float3 v2 = (input[2].pos - input[0].pos).xyz;
                float3 normal = normalize(cross(v1,v2));
                float3 randV = rand(input[1].uv_GS);

                //三角面中心点
                float3 centerPos = (input[0].pos + input[1].pos + input[2].pos) / 3;
                //中心点UV
                float2 centerUV = (input[0].uv_GS + input[1].uv_GS + input[2].uv_GS) / 3;

                //外拓的顶点距离(长度用来控制了中心点往内的外拓距离)
                centerPos -= normal * _Length;
                
                for(uint i = 0; i < 3 ; i++)
                {
                    o.positionHCS = TransformObjectToHClip(input[i].pos + normal * _Power * randV);
                    o.uv = input[i].uv_GS;
                    outStream.Append(o);

                    uint index = (i + 1) % 3;
                    o.positionHCS = TransformObjectToHClip(input[index].pos + normal * _Power * randV);
                    o.uv = input[index].uv_GS;
                    outStream.Append(o);


                    o.positionHCS = TransformObjectToHClip(float4(centerPos + normal * _Power * randV ,1));
                    o.uv = centerUV;
                    outStream.Append(o);

                    //添加三角面
                    outStream.RestartStrip();
                    
                }
            }

            half4 frag (Geom2Frag i) : SV_Target
            {
                return _Color;
            }
            ENDHLSL
        }
    }
}
