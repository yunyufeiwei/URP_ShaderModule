Shader "Art_URP/Base/Fresnel"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _Power("Power",float) = 5
        [Toggle]_Reflection("Reflection",float) = 1
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque"  "Queue" = "Geometry"}

        LOD 100

        pass
        {
            Tags{"LightMode" = "UniversalForward"}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            //关于[Toggle][ToggleOff]如何使用的官方说明文档：https://docs.unity3d.com/ScriptReference/MaterialPropertyDrawer.html
            #pragma multi_compile __ _REFLECTION_ON
            
            struct Attributes
            {
                float4 positionOS     : POSITION;
                float3 normalOS       : NORMAL;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 positionWS   : TEXCOORD;
                float3 normalWS     : TEXCOORD1;
                float3 viewWS       : TEXCOORD2;
            };
            
            //属性定义部分
            //定义纹理采样贴图和采样状态
            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);

            //CBuffer部分，数据参数定义在该结构内，可以使用srp的batch功能
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float  _Power;
            CBUFFER_END

            //定义Fresnel函数
            half Fresnel(half3 normalDir , half3 viewDir , half power)
            {
                return pow(1.0 - saturate(dot(normalize(normalDir) , normalize(viewDir))) , power);
            }

            //添加反射内容，直接使用ReflectionProbe的Cube贴图
            half3 Reflection(float3 viewDirWS, float3 normalWS)
            {
                 float3 reflectVec = reflect(-viewDirWS, normalWS);
                 return DecodeHDREnvironment(SAMPLE_TEXTURECUBE(unity_SpecCube0, samplerunity_SpecCube0, reflectVec), unity_SpecCube0_HDR);
            }

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                //o.viewWS = _WorldSpaceCameraPos - o.positionWS;
                //使用Unity内置的方法计算相机方向
                o.viewWS = GetWorldSpaceViewDir(o.positionWS);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;

                half3 worldNormalDir = normalize(i.normalWS);
                half3 worldViewDir   = normalize(i.viewWS);

                half fresnel = Fresnel(worldNormalDir , worldViewDir , _Power);

                FinalColor = _Color * fresnel;

                //使用Unity的环境cubemap模拟镜面反射的效果，通常基础菲涅尔并不需要此部分
                #if defined(_REFLECTION_ON)
                    half3 cubeMap = Reflection(worldViewDir , worldNormalDir);
                    FinalColor.xyz *= cubeMap;
                #endif

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
