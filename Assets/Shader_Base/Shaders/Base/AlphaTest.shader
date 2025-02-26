Shader "Art_URP/Base/AlphaTest"
{
    Properties
    {
        _AlphaTestTexture("AlphaTestTexture" , 2D) = "white"{}
        _ClipThreshold("AlphaTestThreshold" , Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "AlphaTest" }

        LOD 100

        pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct Attributes
            {
                float4 positionOS    : POSITION;
                float2 texcoord     : TEXCOORD;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD;
                float  fogCoord     : TEXCOORD1;
            };
            
            TEXTURE2D(_AlphaTestTexture);SAMPLER(sampler_AlphaTestTexture);

            //CBuffer部分，数据参数定义在该结构内，可以使用srp的batch功能
            CBUFFER_START(UnityPerMaterial)
                float4 _AlphaTestTexture_ST;
                float  _ClipThreshold;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord , _AlphaTestTexture);

                //通过ComputeFogFactor方法，使用裁剪空间的Z方向深度得到雾的坐标
                o.fogCoord = ComputeFogFactor(o.positionHCS.z);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;

                half alphaTestTexture = SAMPLE_TEXTURE2D(_AlphaTestTexture,sampler_AlphaTestTexture , i.uv).r;

                //可以使用AlphaDiscard方法，但需要在头部定义_ALPHATEST_ON
                //例如：#pragma shader_feature_local fragment __ALPHATEST_ON
                //具体实现Library\PackageCache\com.unity.render-pipelines.universal@12.1.8\ShaderLibrary\ShaderVariablesFunctions.hlsl
                clip(alphaTestTexture - _ClipThreshold);
                
                FinalColor = alphaTestTexture;

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
