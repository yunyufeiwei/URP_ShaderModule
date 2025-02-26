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
                float2 uv_GS        : TEXCOORD0;
                float3 pos          : TEXCOORD1;
            };

            //������ƬԪ�׶δ�������
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
            //inout:�ؼ���
            //TriangleStream: ������ͣ����£�
            // PointStream �� ���ͼԪΪ��
            // LineStream �� ���ͼԪΪ��
            // TriangleStream �� ���ͼԪΪ������

            //��������ʾģʽ
            void geom(triangle Vert2Geom input[3] , inout TriangleStream<Geom2Frag> outStream)
            {
                //-----------����ͨ��������������߲������ô�ֱ��������ķ��߷��� 
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
                    //-----��һ��������ӵ�������б� 
                    outStream.Append(o);
                }
                // ����TriangleStream �������Ҫ�ı����ͼԪ����Ҫÿ������㹻��Ӧ��Ӧ��ͼԪ��ҪRestartStrip()һ���ټ���������һͼԪ��
                // �磺tStream.RestartStrip();
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
