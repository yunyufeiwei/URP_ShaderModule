Shader "ArtShader/FunctionTest/Transformation"
{
    Properties
    {
        _Color("Color" , Color) = (1,1,1,1)
        _BaseMap ("BaseMap", 2D) = "white" {}
        
        //纹理平移属性
        [Header(TranslateProperty)]
        _TranslateVector("TranslateVector",Vector) = (0,0,0,0)
        
        [Header(RotatorProperty)]
        _RotatorVector("RotatorVector",Vector) = (0,0,0,0)
        _Angle("Angle",Float) = 1
        
        [Header(ScaleProperty)]
        _ScaleVector("ScaleVector",Vector) = (1,1,0,0)
        _Speed("Speed",Float) = 0
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
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            //顶点着色器输入结构体
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD;
            };
            //顶点着色器输出结构体
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD;
            };

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _BaseMap_ST;
                float4 _TranslateVector;
                float4 _RotatorVector;
                float  _Angle;
                float4 _ScaleVector;
                float  _Speed;
            CBUFFER_END

            float2 Unity_Rotate_Radians_float(float2 UV, float2 Center, float Rotation)
            {
                UV -= Center;
                float s = sin(Rotation);
                float c = cos(Rotation);
                float2x2 rMatrix = float2x2(c, -s, s, c);
                rMatrix *= 0.5;
                rMatrix += 0.5;
                rMatrix = rMatrix * 2 - 1;
                UV.xy = mul(UV.xy, rMatrix);
                UV += Center;
                return   UV;
            }

            //顶点着色器
            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings) 0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);

                o.positionHCS = vertexInput.positionCS;

                //平移变换
                //相乘法：
                //o.uv = v.texcoord * _BaseMap_ST.xy * _TranslateVector.xy + (_BaseMap_ST.zw + _TranslateVector.zw * _Time.y * _Speed);    //_BaseMap_ST.xy表示了缩放  ，_BaseMap_ST.zw表示了平移
                //矩阵法：
                // float3 uv = float3(v.texcoord , 1.0);
                // float2 time  = _Time.y * _TranslateVector.zw;
                // float3x3 matrix_TranslateVector = float3x3( 1,0,time.x,
                //                                             0,1,time.y,
                //                                             0,0,1);
                // o.uv = mul(matrix_TranslateVector , uv).xy;

                //旋转变换
                // float timeAngle = _Time.y * _Angle;
                //o.uv = Unity_Rotate_Radians_float(v.texcoord,_RotatorVector.zw , timeAngle); //Unity内置方法
                // float2 uvCenter = v.texcoord - _RotatorVector.zw;
                // o.uv = uvCenter;
                // float2x2 rot_Matrix = float2x2(cos(timeAngle),-sin(timeAngle),
                //                                sin(timeAngle),cos(timeAngle));
                // o.uv = mul(rot_Matrix , o.uv);
                // o.uv += _RotatorVector.zw;

                //缩放变换
                //相乘法：
                // float2 time = sin(_Time.y) * _ScaleVector.zw;
                // o.uv = (v.texcoord - _ScaleVector.xy) * _BaseMap_ST.xy * time + _BaseMap_ST.zw;  //v.texcoord - _ScaleVector.xy将缩放点偏移到中心
                // o.uv += _ScaleVector.xy;    //复原缩放点
                //矩阵法：
                // _ScaleVector---xy表示缩放中心点，zw表示缩放的系数
                 float2 scaleValue = abs(sin(_Time.y * _Speed)) * _ScaleVector.zw;
                 float2 uvCenter = v.texcoord - _ScaleVector.xy;
                 float2x2 scale_Matrix = float2x2(scaleValue.x , 0,
                                                  0,scaleValue.y);
                 o.uv = mul(scale_Matrix,uvCenter) + _ScaleVector.xy;
                
                return o;
            }

            //像素着色器
            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap , i.uv);

                FinalColor = baseMap * _Color;

                return FinalColor;
                return half4(i.uv , 0,0);
            }
            ENDHLSL
        }
    }
}
