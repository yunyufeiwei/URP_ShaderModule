Shader "Art_URP/Common/Checker"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("Cull Mode" , int) = 0
        _ColorLight("Color Light",Color) = (1,1,1,1)
        _ColorDark("Color Dark",Color) = (0,0,0,0)
        _GlobalBrightness("GlobalBrightness",Range(1,2)) = 1
        _Repeat("Repeat",float) = 1
        [IntRange]_ModeChoose("ModeChoose" , Range(0,1)) = 0    //[IntRange] 该关键字可以让滑动条只有整数生效
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry" "IgnoreProjector" = "False" }
        LOD 100
        Cull [_CullMode]

        pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //控制模型接受阴影的宏定义
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            //控制模型产生阴影的宏定义
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            //柔化阴影，得到软阴影，如果不添加下面该行，则灯光的softshadow则无效
            #pragma multi_compile _ _SHADOWS_SOFT         

            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD;
                float3 positionWS   : TEXCOORD1;
                float  fogCoord     : TEXCOORD2;
                
            };

            //CBuffer部分，数据参数定义在该结构内，可以使用srp的batch功能
            CBUFFER_START(UnityPerMaterial)
                float4 _ColorLight;
                float4 _ColorDark;
                float _GlobalBrightness;
                float _Repeat;
                float _ModeChoose;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.uv = v.texcoord * _Repeat;

                //通过ComputeFogFactor方法，使用裁剪空间的Z方向深度得到雾的坐标
                o.fogCoord = ComputeFogFactor(o.positionHCS.z);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;

                half3 ambientColor = _GlossyEnvironmentColor.xyz;

                Light light = GetMainLight(TransformWorldToShadowCoord(i.positionWS));
                half3 lightColor = light.color * light.distanceAttenuation;
                half3 selfShadow = lightColor * light.shadowAttenuation;

                //对UV进行计算，得到xy方向的不同颜色，从中心分离，计算明暗分离，这里乘以0.5得到灰色和黑色
                float2 uvTex = floor(i.uv * 2) * 0.5;
                float MaskTex = saturate(frac(uvTex.x + uvTex.y) * 2);
                half CheckerTex = lerp(_ColorLight,_ColorDark,MaskTex);

                //使用世界空间的坐标为插值来混合颜色
                half SolidColor= lerp(_ColorDark,_ColorLight,i.positionWS.y);

                FinalColor = float4(saturate(lerp(CheckerTex,SolidColor,floor(_ModeChoose)) * _GlobalBrightness * selfShadow + ambientColor), 1);
                //混合雾效
                FinalColor.rgb = MixFog(FinalColor.rgb, i.fogCoord);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}