Shader "ArtShader/FunctionTest/VertexTransformation"
{
    Properties
    {
        _Color("Color" , Color) = (1,1,1,1)
        
        [Space(20)]
        [Header(CommonProperty)]
        _Speed("Speed",Float) = 1
        
        [Space(10)]
        [Header(MoveProperty)]
        _TranslateVector("TranslateVector",Vector) = (0,0,0,0)
        
        [Space(10)]
        [Header(RotatorProperty)]
        _RotatorVector("RotatorVector",Vector) = (0,0,0,0)
        [IntRange]_Angle("Angle",Range(0,360)) = 0
        _axisPos("axisPos",Vector) = (0,0,0,0)
        
        [Space(10)]
        [Header(ScaleProperty)]
        _ScaleVector("ScaleVector" , Vector) = (1,1,1,0)
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

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 positionWS   : TEXCOORD1;
                float2 uv           : TEXCOORD;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float  _Speed;
                float4 _TranslateVector;
                float4 _RotatorVector;
                float  _Angle;
                float3 _axisPos;
                float4 _ScaleVector;
            CBUFFER_END

            //封装到变换的hlsl中
            float3 Unity_RotateAboutAxis_Radians_float(float3 In, float3 Axis, float Rotation)
            {
                float s = sin(Rotation);
                float c = cos(Rotation);
                float one_minus_c = 1.0 - c;
            
                Axis = normalize(Axis);
                float3x3 rot_mat =
                {   one_minus_c * Axis.x * Axis.x + c , one_minus_c * Axis.x * Axis.y - Axis.z * s , one_minus_c * Axis.z * Axis.x + Axis.y * s,
                    one_minus_c * Axis.x * Axis.y + Axis.z * s , one_minus_c * Axis.y * Axis.y + c , one_minus_c * Axis.y * Axis.z - Axis.x * s,
                    one_minus_c * Axis.z * Axis.x - Axis.y * s , one_minus_c * Axis.y * Axis.z + Axis.x * s , one_minus_c * Axis.z * Axis.z + c
                };
                return  mul(rot_mat,  In);
            }
            
            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings) 0;
                
                o.uv = v.texcoord;

                //==============================================================================移动变换==============================================================================
                //在模型空间的坐标系下进行偏移
                //因为v.positionOS获取到的就是模型空间下的顶点坐标，因此想要在模型空间下对顶点进行移动操作，只需要把移动的值叠加到顶点上。
                //相乘法：
                // float3 positionOS = v.positionOS.xyz;
                // float frequency = sin(_Time.y * _Speed);    //计算频率
                // positionOS += abs((frequency * float3(_TranslateVector.x , _TranslateVector.y , _TranslateVector.z))); //因为裁剪空间要在最后计算，因此模型空间的顶点变换要在裁剪变换之前
                // VertexPositionInputs vertexInput = GetVertexPositionInputs(positionOS.xyz);    //将移动得到的新的位置作为裁剪空间的输入位置信息,这里的顶点由模型空间到裁剪空间的计算在函数中封装好了的
                // o.positionHCS = vertexInput.positionCS;
                //矩阵法：
                // float4 positionOS = v.positionOS;
                // float  frequency = abs(sin(_Time.y * _Speed));    //计算频率
                // float4 translateVal = _TranslateVector * frequency;
                // float4x4 matrix_TranslateVector = float4x4( 1,0,0,translateVal.x,
                //                                             0,1,0,translateVal.y,
                //                                             0,0,1,translateVal.z,
                //                                             0,0,0,1);
                // positionOS = mul(matrix_TranslateVector , positionOS); //因为裁剪空间要在最后计算，因此模型空间的顶点变换要在裁剪变换之前
                // VertexPositionInputs vertexInput = GetVertexPositionInputs(positionOS.xyz);    //将移动得到的新的位置作为裁剪空间的输入位置信息,这里的顶点由模型空间到裁剪空间的计算在函数中封装好了的
                // o.positionHCS = vertexInput.positionCS;
                
                //在世界空间的坐标系下进行偏移
                //相乘法：
                // float frequency = sin(_Time.y * _Speed);    //计算频率
                // VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                // vertexInput.positionWS += abs(frequency * float3(_TranslateVector.x , _TranslateVector.y , _TranslateVector.z));    //通过原始的模型空间的顶点坐标计算出来结构体的信息，然后在计算世界空间下的顶点位置
                // o.positionHCS = TransformWorldToHClip(vertexInput.positionWS);
                //矩阵法：
                // VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                // float4 positionWS = float4(vertexInput.positionWS , 1);  //得到世界空间下的顶点位置 ,设置世界空间下的顶点的w分量为0
                // float frequency = abs(sin(_Time.y * _Speed));    //计算频率
                // float4 translateVal = _TranslateVector * frequency;
                // // float4x4 matrix_TranslateVector = float4x4(  1,0,0,translateVal.x,
                // //                                              0,1,0,translateVal.y,
                // //                                              0,0,1,translateVal.z,
                // //                                              0,0,0,1);
                // //o.positionWS = mul(matrix_TranslateVector , float4(positionWS.xyz,1));  //将平移后的世界空间的位置转换为齐次坐标(通常W分量为1，除非有透视需求)
                // //o.positionWS = mul(matrix_TranslateVector , float4(positionWS.xyz,1));
                // float3x3 matrix_Trans = float3x3(  1,0,0,
                //                                    0,1,0,
                //                                    0,0,1);
                // o.positionWS = mul(matrix_Trans , positionWS) + translateVal;
                //
                // o.positionHCS = TransformWorldToHClip(o.positionWS);

                //==============================================================================绕轴移动==============================================================================
                //绕模型轴心点在模型空间下的移动
                // float time = _Time.y * _Speed;
                // float radius = 5;
                // float angle = time * 2 * PI/100;
                // float3 offset = float3(radius * cos(angle),0,radius * sin(angle));
                // float3 positionOS = v.positionOS.xyz;
                // positionOS += offset;
                // VertexPositionInputs vertexInput = GetVertexPositionInputs(positionOS);
                // o.positionHCS = TransformObjectToHClip(vertexInput.positionWS);
                
                //绕模型轴心点在世界空间下的移动
                // float time = _Time.y * _Speed;
                // float radius = 5;
                // float angle = time * 2 * PI/100;
                // float3 offset = float3(radius * cos(angle),0,radius * sin(angle));
                // VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                // vertexInput.positionWS += offset;
                // o.positionHCS = TransformWorldToHClip(vertexInput.positionWS);

                //==============================================================================旋转变换==============================================================================
                //在模型空间的坐标系下进行旋转
                // float rotatorAngle = _Time.y * _Angle;
                // float3 tempPos = Unity_RotateAboutAxis_Radians_float(v.positionOS.xyz , _RotatorVector.xyz , rotatorAngle);
                // o.positionHCS = TransformObjectToHClip(tempPos);

                //在世界空间的坐标系下绕轴心点进行旋转
                // VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                // float rotatorAngle = _Time.y * _Angle;
                // float3 offset = vertexInput.positionWS - _axisPos;      //这里需要使用C#脚本传递物体在世界场景中的位置，先把物体在场景中位置减去，这样就把重心归到了轴心，然后在进行变换
                // float3 tempPosWS = Unity_RotateAboutAxis_Radians_float(offset , _RotatorVector.xyz , rotatorAngle);
                // float3 newPositionWS = tempPosWS + _axisPos;            //变换完成之后，在将位移的坐标加回来
                // o.positionHCS = TransformWorldToHClip(newPositionWS);
                
                //==============================================================================缩放变换==============================================================================
                //在模型空间下的坐标系下进行缩放
                //相乘法：
                // float3 time = abs(sin(_Time.y * _Speed)) * _ScaleVector.xyz;       //速度和时间相乘，则频率变快，然后用_Scale和sin()值相乘，振幅变大(也就是缩放大小)
                // float3 pos = v.positionOS.xyz;
                // pos += v.positionOS.xyz * time;
                // o.positionHCS = TransformObjectToHClip(pos); 
                //矩阵法：
                float time = abs(sin(_Time.y * _Speed));
                float4 scaleVal = time * _ScaleVector;
                float4x4 mat_Scale= float4x4(scaleVal.x , 0 , 0 ,0,
                                              0 , scaleVal.y , 0 ,0,
                                              0 , 0 , scaleVal.z , 0,
                                              0 , 0 , 0 , 1);
                v.positionOS += mul(mat_Scale , v.positionOS);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);

                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                FinalColor = _Color;
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
