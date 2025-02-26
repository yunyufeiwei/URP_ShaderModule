Shader "Art_URP/FunctionTest/Polygon"
{
    Properties
    {
        _Num("Num", Int) = 3
		_Size("Size", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" }

        Pass
        {
            Tags{"RenderPipeline" = "UniversalPipeline"}
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            CBUFFER_START(UnityPerMaterial)
                float _Num;
                float  _Size;
            CBUFFER_END
      
            Varyings vert (Attributes v)
            {
                UNITY_SETUP_INSTANCE_ID(v);

                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.texcoord;
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                half4 FinalColor;

                //i.uv的(0,0)点在左下角，通过*2 - 1将原点变换到中心为止
                half2 uv = i.uv * 2 - 1;

                //[0,2π]，将整个界面变成角度分布（极坐标）
                float a = atan2(uv.x , uv.y) + PI;
                //一条边对应的角度（中心连接的两个端点）
                float r = (2 * PI) / float(_Num);

                float d = cos(floor(0.5 + a / r) * r - a) * length(uv);

                FinalColor = half4(1 - step(_Size , d).rrr , 1);

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
