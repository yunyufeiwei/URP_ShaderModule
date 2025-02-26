Shader "Art_URP/FunctionTest/GeometryShader_Triangle"
{
    Properties
    {
        _Color("Color" , Color) = (1,1,1,1)
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

            // 输入类型 point v2g input[1]
            // point ： 输入图元为点，1个顶点
            // line ： 输入图元为线，2个顶点
            // triangle ： 输入图元为三角形，3个顶点
            // lineadj ： 输入图元为带有邻接信息的直线，由4个顶点构成3条线
            // triangleadj ： 输入图元为带有邻接信息的三角形，由6个顶点构成

            // 输出类型  inout PointStream<g2f> outStream  可以自定义结构体，g2f、v2f...
            //inout:关键词
            //TriangleStream: 输出类型，如下：
            // PointStream ： 输出图元为点
            // LineStream ： 输出图元为线
            // TriangleStream ： 输出图元为三角形

            //三角形显示模式
            void geom(triangle Vert2Geom input[3] , inout TriangleStream<Geom2Frag> outStream)
            {
                //-----------这里通过三角面的两个边叉乘来获得垂直于三角面的法线方向 
                float3 v1 = (input[1].pos - input[0].pos).xyz; 
                float3 v2 = (input[2].pos - input[0].pos).xyz;

                float3 normal = normalize(cross(v1,v2));
                float3 randV = rand(input[1].uv_GS);

                for(int i = 0; i < 3 ; i++)
                {
                    Geom2Frag o = (Geom2Frag)0;
                    
                    float3 newPos = input[i].pos + normal * _Power * randV;
                    o.positionHCS = TransformObjectToHClip(newPos);
                    
                    o.uv = input[i].uv_GS;
                    //-----将一个顶点添加到输出流列表 
                    outStream.Append(o);
                }
                // 对于TriangleStream ，如果需要改变输出图元，需要每输出点足够对应相应的图元后都要RestartStrip()一下再继续构成下一图元，
                // 如：tStream.RestartStrip();
                // outStream.RestartStrip(); 
                outStream.RestartStrip(); 
            }

            half4 frag (Geom2Frag i) : SV_Target
            {
                return _Color;
            }
            ENDHLSL
        }
    }
}
