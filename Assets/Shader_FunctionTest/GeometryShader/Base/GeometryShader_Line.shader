Shader "Art_URP/FunctionTest/GeometryShader_line"
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

            //顶点向集合阶段传递数据
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
            
            //线框显示模式
             void geom (line  Vert2Geom input[2] , inout LineStream<Geom2Frag> outStream)
             {
                 for(int i = 0;i<2;i++)
                 {
                     Geom2Frag o = (Geom2Frag)0;
                     o.positionHCS = input[i].positionGS;
                     o.uv = input[i].uv_GS;
                     outStream.Append(o);
                 }

                // 对于TriangleStream ，如果需要改变输出图元，需要每输出点足够对应相应的图元后都要RestartStrip()一下再继续构成下一图元，
                // 如：tStream.RestartStrip();
                // outStream.RestartStrip(); 
             }

            half4 frag (Geom2Frag i) : SV_Target
            {
                return _Color;
            }
            ENDHLSL
        }
    }
}
