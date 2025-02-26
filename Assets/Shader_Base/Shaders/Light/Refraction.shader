//折射和物理上没啥区别，实现的本质就是便宜UV，使物体后面的物体看起来发生偏移。因为折射的是后面的物体，所以需要一张额外的纹理来采样，可以是一张普通纹理、反射探针纹理、RenderTexture纹理
//直接使用URP自带的_CameraOpaqueTexture来采样，这个纹理会把不透明的物体渲染上去（仅不透明）
//要使用_CameraOpaqueTexture，必须在Universal Render Pipeline Asset中勾选Opaque Texture选项
//************同时，"RenderType" = "Transparent" "Queue" = "Transparent"需要设置为半透明 ************************

//总结：
//使用自带的_CameraOpaqueTexture，仅不透明物体会渲染上去

Shader "Art_URP/Base/Light/Refraction"
{
    Properties
    {
        _Intensity("Intensity",float) = 1.0
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent"}
        LOD 100

        pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS     : POSITION;
                float3 normalOS       : NORMAL;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 normalWS     : TEXCOORD1;
                float3 viewWS       : TEXCOORD2;
            };

            //Library\PackageCache\com.unity.render-pipelines.universal@14.0.8\ShaderLibrary\DeclareOpaqueTexture.hlsl
            TEXTURE2D(_CameraOpaqueTexture);SAMPLER(sampler_CameraOpaqueTexture);

            CBUFFER_START(UnityPerMaterial)
            float  _Intensity;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.viewWS = GetWorldSpaceViewDir(positionWS);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;

                half3 worldNormalDir = normalize(i.normalWS);
                half3 worldViewDir = normalize(i.viewWS);

                //屏幕坐标
                half2 screenUV = i.positionHCS.xy / _ScreenParams.xy;

                half ratio = (1 - pow(dot(worldNormalDir , worldViewDir) , 2.0)) * _Intensity;

                half3 refractionOffset = _Intensity * TransformWorldToViewDir(worldNormalDir) * ratio;

                FinalColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture , sampler_CameraOpaqueTexture , screenUV + refractionOffset.xy);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
