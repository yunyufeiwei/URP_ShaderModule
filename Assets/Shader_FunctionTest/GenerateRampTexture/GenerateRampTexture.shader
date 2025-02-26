Shader "Art_URP/FunctionTest/GenerateRampTexture"
{
    Properties
    {
        
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" "IgnoreProjector" = "False"}

        LOD 100

        pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS     : POSITION;
                float2 texcoord     : TEXCOORD;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD;
                float  fogCoord     : TEXCOORD1;
            };
            
            //属性定义部分
            //定义纹理采样贴图和采样状态，这里的采样纹理没有在property中定义，采用的方法是使用C#全局定义_RampTexture的方式赋予颜色
            TEXTURE2D(_RampTexture);SAMPLER(sampler_RampTexture);

            //CBuffer部分，数据参数定义在该结构内，可以使用srp的batch功能
            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.texcoord;

                //通过ComputeFogFactor方法，使用裁剪空间的Z方向深度得到雾的坐标
                o.fogCoord = ComputeFogFactor(o.positionHCS.z);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;

                half4 rampColor = SAMPLE_TEXTURE2D(_RampTexture,sampler_RampTexture , i.uv);

                FinalColor = rampColor;
                //混合雾效
                FinalColor.rgb = MixFog(FinalColor.rgb , i.fogCoord);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
