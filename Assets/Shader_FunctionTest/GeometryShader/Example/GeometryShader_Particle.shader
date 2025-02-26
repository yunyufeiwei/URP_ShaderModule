Shader "Art_URP/FunctionTest/GeometryShader_Particle"
{
    Properties
    {
        _Color("Color" , Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        [PowerSlider(2.0)]_Size("Size",Range(0,20)) = 0.0
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
                float3 normal       : NORMAL;
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
            };
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _MainTex_ST;
                float  _Size;
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
            void geom(triangle Vert2Geom input[3] , inout PointStream<Geom2Frag> pointStream)
            {
                Geom2Frag o = (Geom2Frag)0;
                
                //-----------����ͨ��������������߲������ô�ֱ��������ķ��߷��� 
                float3 v1 = (input[1].positionGS - input[0].positionGS).xyz; 
                float3 v2 = (input[2].positionGS - input[0].positionGS).xyz;
                float3 normalDir = normalize(cross(v1,v2));

                //��������ϲ���һ��
				float3 tempPos = (input[0].positionGS + input[1].positionGS + input[2].positionGS) / 3;
				//�ط��߷���λ��
				tempPos += normalDir * _Size;
                
				o.positionHCS = TransformObjectToHClip(tempPos);
				o.uv= (input[0].uv_GS + input[1].uv_GS + input[2].uv_GS) / 3;
				//��Ӷ���
				pointStream.Append(o);
            }

            half4 frag (Geom2Frag i) : SV_Target
            {
                float4 FinalColor = SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , i.uv) * _Color;
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
