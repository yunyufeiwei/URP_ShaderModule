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
            //����һ��������ɫ��
            #pragma geometry geom
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            //
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD;
            };

            //�����򼸺ν׶δ�������
            struct Vert2Geom
            {
                float4 positionGS   : SV_POSITION;
                float2 uv_GS : TEXCOORD1;
            };

            //������ƬԪ�׶δ�������
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

            //��̬�ƶ��������õ���󶥵���� 
            // [NVIDIA08]ָ������GS�����1��20������֮��ʱ������ʵ��GS�����ܷ�ֵ�����GS�����27-40������֮�䣬�������½�50����
            [maxvertexcount(20)]

            // �������� point v2g input[1]
            // point �� ����ͼԪΪ�㣬1������
            // line �� ����ͼԪΪ�ߣ�2������
            // triangle �� ����ͼԪΪ�����Σ�3������
            // lineadj �� ����ͼԪΪ�����ڽ���Ϣ��ֱ�ߣ���4�����㹹��3����
            // triangleadj �� ����ͼԪΪ�����ڽ���Ϣ�������Σ���6�����㹹��

            // �������  inout PointStream<g2f> outStream  �����Զ���ṹ�壬g2f��v2f...
            // inout:�ؼ���
            // TriangleStream: ������ͣ����£�
            // PointStream �� ���ͼԪΪ��
            // LineStream �� ���ͼԪΪ��
            // TriangleStream �� ���ͼԪΪ������

            //����ʾģʽ
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
