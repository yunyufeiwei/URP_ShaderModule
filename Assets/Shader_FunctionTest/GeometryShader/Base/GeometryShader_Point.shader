Shader "Art_URP/FunctionTest/GeometryShader_Point"
{
    Properties
    {
        _Color("Color" , Color) = (1,1,1,1)
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

            //顶点向几何阶段传递数据
            struct Vert2Geom
            {
                float4 positionGS   : SV_POSITION;
                float2 uv_GS : TEXCOORD1;
            };

            //几何向片元阶段传递数据
            struct Geom2Frag
            {
                float4 positionHCS : SV_POSITION; 
                float2 uv : TEXCOORD0; 
            };
            
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
            CBUFFER_END

            Vert2Geom vert (Attributes v)
            {
                Vert2Geom o = (Vert2Geom) 0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);

                o.positionGS = vertexInput.positionCS;
                
                o.uv_GS = v.texcoord;
                return o;
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
            // inout:关键词
            // TriangleStream: 输出类型，如下：
            // PointStream ： 输出图元为点
            // LineStream ： 输出图元为线
            // TriangleStream ： 输出图元为三角形

            //点显示模式
            void geom(point Vert2Geom input[1] , inout PointStream<Geom2Frag> outStream)
            {
                Geom2Frag o = (Geom2Frag)0;
                o.positionHCS = input[0].positionGS;
                o.uv = input[0].uv_GS;
                outStream.Append(o);
            }

            half4 frag (Geom2Frag i) : SV_Target
            {
                return _Color;
            }
            ENDHLSL
        }
    }
}
