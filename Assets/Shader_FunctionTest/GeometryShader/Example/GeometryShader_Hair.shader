Shader "Art_URP/FunctionTest/GeometryShader_Hair"
{
    Properties
    {
        _Color("Color" , Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        [PowerSlider(3.0)]_Length("Length",Range(0,20)) = 1
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
                float4 positionGS   : POSITION;
                float2 uv_GS        : TEXCOORD0;
            };

            //������ƬԪ�׶δ�������
            struct Geom2Frag
            {
                float4 positionHCS : SV_POSITION; 
                float2 uv : TEXCOORD0;
                float4 color        : COLOR;
            };
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _MainTex_ST;
                float  _Length;
            CBUFFER_END

            Vert2Geom vert (Attributes v)
            {
                Vert2Geom o = (Vert2Geom) 0;

                o.positionGS = v.positionOS;
                
                o.uv_GS = v.texcoord;
                return o;
            }

            //��̬�ƶ��������õ���󶥵���� 
            // [NVIDIA08]ָ������GS�����1��20������֮��ʱ������ʵ��GS�����ܷ�ֵ�����GS�����27-40������֮�䣬�������½�50����
            [maxvertexcount(20)]

            //��������ʾģʽ
            void geom(triangle Vert2Geom input[3] , inout TriangleStream<Geom2Frag> outStream)
            {
                Geom2Frag o = (Geom2Frag)0;
                
                //-----------����ͨ��������������߲������ô�ֱ��������ķ��߷��� 
                float3 v1 = (input[1].positionGS - input[0].positionGS).xyz; 
                float3 v2 = (input[2].positionGS - input[0].positionGS).xyz;
                float3 normal = normalize(cross(v1,v2));

                //���������ĵ�
                float3 centerPos = (input[0].positionGS + input[1].positionGS + input[2].positionGS) / 3;
                //���ĵ�UV
                float2 centerUV = (input[0].uv_GS + input[1].uv_GS + input[2].uv_GS) / 3;

                //��������������ĵ�λ���ط��ߵķ�������
                centerPos += float4(normal , 0).xyz * _Length;

                for(uint i = 0; i < 3 ; i++)
                {
                    o.positionHCS = TransformObjectToHClip(input[i].positionGS);
                    o.uv = input[i].uv_GS;
                    o.color = float4(0,0,0,1);
                    outStream.Append(o);

                    uint index = (i + 1) % 3;
                    o.positionHCS = TransformObjectToHClip(input[index].positionGS);
                    o.uv = input[index].uv_GS;
                    o.color = float4(0,0,0,1);
                    outStream.Append(o);

                    //�ⲿ��ɫ��
                    o.positionHCS = TransformObjectToHClip(centerPos);
                    o.uv = centerUV;
                    o.color = float4(1,1,1,1);
                    outStream.Append(o);

                    //���������
                    outStream.RestartStrip();
                    
                }
            }

            half4 frag (Geom2Frag i) : SV_Target
            {
                float4 FinalColor = SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , i.uv) * i.color * _Color;
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
