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
            //����һ��������ɫ��
            #pragma geometry geom
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            //
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD;
            };

            //�����򼯺Ͻ׶δ�������
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
            
            //�߿���ʾģʽ
             void geom (line  Vert2Geom input[2] , inout LineStream<Geom2Frag> outStream)
             {
                 for(int i = 0;i<2;i++)
                 {
                     Geom2Frag o = (Geom2Frag)0;
                     o.positionHCS = input[i].positionGS;
                     o.uv = input[i].uv_GS;
                     outStream.Append(o);
                 }

                // ����TriangleStream �������Ҫ�ı����ͼԪ����Ҫÿ������㹻��Ӧ��Ӧ��ͼԪ��ҪRestartStrip()һ���ټ���������һͼԪ��
                // �磺tStream.RestartStrip();
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
