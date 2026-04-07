Shader "Miami/VFX/VFX_Standard"
{
    Properties
    {
        //------------------
        [HideInInspector]_MainTexPopUp("",Float) = 0
        [HideInInspector]_MainTexRGBA("",Vector) = (0,0,0,0)
        [HideInInspector]_ColorSwitch("",float) = 0
        
        [Toggle]_IsStreamerMode("IsStreamerMode",float) = 0

        [HDR]_Color("基础颜色" , Color) = (1,1,1,1)
        _MainTex("基础贴图",2D) = "white"{}
        _AlphaValue("Alpha值" , Range(0,10)) = 1
        _USpeed("USpeed",float) = 0
        _VSpeed("VSpeed",float) = 0
        [HDR]_LerpColor("LerpColor",Color) = (1,1,1,1)
        _LerpValue("LerpValue",Range(0,1)) = 1
        [Toggle]_DiffuseRotate("贴图旋转",float) = 0
        _DiffuseAngle("旋转角度", Range(0,360)) = 0
        
        //---------------
        [Toggle]_DiffuseMask("基础遮罩",float) = 0
        [Foldout] _DiffuseMaskLayerShown ("", Float) = 1 

        [HideInInspector]_MaskTexPopUp("",Float) = 0
        [HideInInspector]_MaskTexRGBA("",vector) = (1,1,1,1)

        _DiffuseMaskTex("遮罩贴图",2D) = "white"{}
        _Mask_USpeed("Mask_USpeed",float) = 0
        _Mask_VSpeed("Mask_VSpeed",float) = 0
        [Toggle]_MaskRotate("遮罩旋转",float) = 0
        _MaskAngle("旋转角度",Range(0,360)) = 0

        //-----------------
        [Toggle]_Distortion("扭曲效果",float) = 0
        [Foldout] _DistortionLayerShown ("", Float) = 1

        [HideInInspector]_DistortionPopUp("",Float) = 0
        [HideInInspector]_DistortionRGBA("",Vector) = (1,1,1,1)

        _DistortionTex("扭曲贴图",2D) = "white"{}
        _DistortionIntensity("扭曲强度",float) = 1
        _Distortion_USpeed("Distortion_USpeed",float) = 0
        _Distortion_VSpeed("Distortion_VSpeed",float) = 0

        //-------------------------
        [Toggle]_Dissolution("溶解效果",float) = 0
        [Foldout] _DissolutionLayerShown ("",Float) = 1
        
        [HideInInspector]_DissolutionPopUp("",Float) = 0
        [HideInInspector]_DissolutionRGBA("",Vector) = (1,1,1,1)

        _DissolutionTex("溶解贴图",2D) = "white"{}
        _Dissolution_USpeed("Dissolution_USpeed",float) = 0
        _Dissolution_VSpeed("Dissolution_VSpeed",float) = 0
        _Dissolvability("溶解程度",Range(0,1)) = 0
        _Eclosion("边缘羽化",Range(0,1)) = 1
        [HDR]_EdgeColor("边缘颜色",Color) = (1,1,1,1)
        _EdgeWidth("边缘宽度",range(0,1)) = 0

        [HideInInspector] _Comp("Comp",Float) = 1
        [HideInInspector] _CompMode ("__Compmode",Float) = 1
        
        [Toggle]_UseFlicker("启用闪烁",Float) = 0
        _FlickerFrequency("FlickerFrequency" , Float) = 0.3
        _FlickerAmplitude("Amplitude",Float) = 2
        
//        [Toggle]_WorldClip("水平面下裁剪",Float) = 0
//        _WorldClipRange("水平面下裁剪",Range(1,10)) = 5

        _ZTest("ZTest",Float) = 0  
        [HideInInspector] _ZTestMode ("__Zmode",Float) = 0.0 

        [HideInInspector] _BlendMode ("__mode",Float) = 0.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _FaceMode ("__face", Float) = 0.0
        [HideInInspector] _CullMode ("__cull", Float) = 2.0
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" "RenderType"="Transparent" "PreviewType"="Plane"}
        //Blend [_SrcFactor][_DstFactor]
        Blend SrcAlpha [_DstBlend]
        Cull [_CullMode]
        ZWrite off
        ZTest [_ZTest]

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _DIFFUSEROTATE_ON
            #pragma multi_compile _ _DIFFUSEMASK_ON
            #pragma multi_compile _ _MASKROTATE_ON
            #pragma multi_compile _ _DISTORTION_ON
            #pragma multi_compile _ _DISSOLUTION_ON
            #pragma multi_compile _ _USEFLICKER_ON

            #pragma multi_compile _ _ISSTREAMERMODE_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float4 color        : COLOR;
                float2 texcoord     : TEXCOORD;
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS   : SV_POSITION;
                float4 color         : COLOR;
                float2 uv            : TEXCOORD0;
                float3 positionWS    : TEXCOORD1;
                float2 uv1           : TEXCOORD2;
                float2 uv2           : TEXCOORD3;
                float2 uv3           : TEXCOORD4;
                float3 normalWS     : TEXCOORD5;
            };

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_DiffuseMaskTex);SAMPLER(sampler_DiffuseMaskTex);
            TEXTURE2D(_DistortionTex);SAMPLER(sampler_DistortionTex);
            TEXTURE2D(_DissolutionTex);SAMPLER(sampler_DissolutionTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _MainTexRGBA;
                float _IsStreamerMode;
                float4 _Color;
                float  _AlphaValue;
                float  _USpeed;
                float  _VSpeed;
                float4 _LerpColor;
                float  _LerpValue;
                float  _ColorSwitch;
                //float  _WorldClip;
                //float  _WorldClipRange;
                float  _DiffuseAngle;

                float4 _MaskTexRGBA;
                float4 _DiffuseMaskTex_ST;
                float _Mask_USpeed;
                float _Mask_VSpeed;
                float _MaskAngle;

                float4 _DistortionRGBA;
                float4 _DistortionTex_ST;
                float  _DistortionIntensity;
                float  _Distortion_USpeed;
                float  _Distortion_VSpeed;

                float4 _DissolutionTex_ST;
                float4 _DissolutionRGBA;
                float  _Dissolution_USpeed;
                float  _Dissolution_VSpeed;
                float  _Dissolvability;
                float  _Eclosion;
                float4 _EdgeColor;
                float  _EdgeWidth;

                float _FlickerFrequency;
                float _FlickerAmplitude;
            CBUFFER_END


            float3 Saturation_float(float3 In, float Saturation)
            {
                float luma = dot(In, float3(0.2126729, 0.7151522, 0.0721750));
                float3 mainTex = luma.xxx + Saturation.xxx * (In - luma.xxx);
                return  mainTex;
            }
                

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.color = v.color;
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.normalWS  = TransformObjectToWorldNormal(v.normalOS);

                //主纹理是否启用旋转
                #if _DIFFUSEROTATE_ON
                    half2 uv_Main = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                    half Angle_sin;
                    half Angle_cos;
                    sincos(_DiffuseAngle*0.01745 , Angle_sin , Angle_cos);
                    half2x2 RotateMatrix = half2x2(Angle_cos , Angle_sin,
                                                -Angle_sin , Angle_cos);
                    o.uv = mul(uv_Main-half2(0.5,0.5),RotateMatrix)  + half2(0.5,0.5);                           
                #else
                    o.uv = TRANSFORM_TEX(v.texcoord , _MainTex);
                #endif
                    o.uv += half2(_USpeed * _Time.y,_VSpeed * _Time.y);

                //遮罩纹理
                #if _DIFFUSEMASK_ON
                    #if _MASKROTATE_ON
                    half2 uv_Mask = v.texcoord * _DiffuseMaskTex_ST.xy + _DiffuseMaskTex_ST.zw;
                    half MaskAngle_sin;
                    half MaskAngle_cos;
                    sincos(_MaskAngle*0.01745 , MaskAngle_sin , MaskAngle_cos);
                    half2x2 MaskRotateMatrix = half2x2(MaskAngle_cos , MaskAngle_sin,
                                                      -MaskAngle_sin , MaskAngle_cos);
                    o.uv1 = mul(uv_Mask-half2(0.5,0.5),MaskRotateMatrix)  + half2(0.5,0.5); 
                    #else 
                    o.uv1 = TRANSFORM_TEX(v.texcoord , _DiffuseMaskTex);
                    #endif
                o.uv1 += half2(_Mask_USpeed * _Time.y , _Mask_VSpeed * _Time.y);
                #endif

                //扭曲纹理uv
                #if _DISTORTION_ON
                o.uv2 = TRANSFORM_TEX(v.texcoord , _DistortionTex);
                o.uv2 += half2(_Distortion_USpeed * _Time.y , _Distortion_VSpeed * _Time.y);
                #endif

                //溶解纹理uv
                #if _DISSOLUTION_ON
                o.uv3 = TRANSFORM_TEX(v.texcoord , _DissolutionTex);
                o.uv3 += (_Dissolution_USpeed * _Time.y , _Dissolution_VSpeed * _Time.y);
                #endif

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                float4 FinalColor;

                Light light = GetMainLight();
                half3 lightDir = light.direction;
                half3 lightColor = light.color * light.distanceAttenuation;

                half3 worldNormalDir = normalize(i.normalWS);

                half distortionSwitch = 0;
                half commonDistortion = 0;

                #if _DISTORTION_ON
                    half4 Distortion = SAMPLE_TEXTURE2D(_DistortionTex,sampler_DistortionTex,i.uv2);
                    half  dotDistortion = dot(Distortion , _DistortionRGBA);//通过点积取纹理的通道
                    i.uv += dotDistortion * _DistortionIntensity;
                    commonDistortion = dotDistortion * _DistortionIntensity;
                    distortionSwitch = 1;
                #endif

                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , i.uv);
                //迭代内容：主播模式
                // #if  _ISSTREAMERMODE_ON
                //     FinalColor = float4(Saturation_float(mainTex,0),mainTex.a);
                // #else
                    FinalColor = mainTex;
                // #endif

                //----MainTextureVar alpha Mask---------
                half col2 = dot(FinalColor.rgba , _MainTexRGBA.rgba);
                half3 ColorOutRGB = lerp(FinalColor.rgb , half3(col2,col2,col2),_ColorSwitch);
                half4 col3 = half4(ColorOutRGB,mainTex.a);
                FinalColor = col3;
                //--------------------------------------

                #if _DIFFUSEMASK_ON
                    half4 diffuseMask = SAMPLE_TEXTURE2D(_DiffuseMaskTex,sampler_DiffuseMaskTex,i.uv1);
                    half  diffuseMaskDot = dot(diffuseMask,_MaskTexRGBA);
                    FinalColor.a = FinalColor.a * diffuseMaskDot;
                #endif

                FinalColor.rgb = FinalColor.rgb * _Color.rgb;
                half value = saturate(FinalColor.a);
                float lerpdegree = saturate(1-value-_LerpValue);
                FinalColor.rgb = lerp(FinalColor.rgb , _LerpColor.rgb , lerpdegree);

                half dissolutionAlphaSwitch = 0;
                #if _DISSOLUTION_ON
                    dissolutionAlphaSwitch = 1;
                    half4 Dissolution = SAMPLE_TEXTURE2D(_DissolutionTex , sampler_DissolutionTex , lerp(i.uv3,i.uv3 + commonDistortion , dissolutionAlphaSwitch));
                    half dotDissolution = dot(Dissolution , _DissolutionRGBA);
                    half dissolve = (dotDissolution - ((1-i.color.a)+_Dissolvability));
                    float degree = saturate((dissolve-_EdgeWidth)*lerp(0,100,_Eclosion));
                    float A = saturate(dissolve*lerp(0,100,_Eclosion));
                    FinalColor.rgb = lerp(_EdgeColor.rgb,FinalColor.rgb,degree);
                    FinalColor.a *= A;
                #endif

                // int additionalLightCount = GetAdditionalLightsCount(); //获取额外光源数量
                // for(int j = 0; j < additionalLightCount; ++j)
                // {
                //     light = GetAdditionalLight(j,i.positionWS);     //根据Index获取额外的光源数据
                //     half3 attenuatedLightColor = light.color * light.distanceAttenuation;
                //     FinalColor.rgb += LightingLambert(attenuatedLightColor , light.direction , worldNormalDir);
                // }

                FinalColor.rgb = FinalColor.rgb * i.color.rgb;
                #if _USEFLICKER_ON
                    float timeFloat = frac(_Time.y * _FlickerFrequency);
                    float PingpongTime = min(timeFloat , 1 - timeFloat) * _FlickerAmplitude;
                    FinalColor.rgb = FinalColor.rgb * i.color.rgb  * (PingpongTime + 0.02);
                    FinalColor.a *= i.color.a;
                #endif
                
                half DissolutionVertexToggleSwitchA = 1;

                //half worldposHigh = lerp(1,(saturate((i.positionWS).y*_WorldClipRange)),_WorldClip);
                FinalColor.a = clamp((FinalColor.a * DissolutionVertexToggleSwitchA * _AlphaValue),0,1)*lerp(i.color.a,1,dissolutionAlphaSwitch);
                
                return FinalColor;
            }

            ENDHLSL  
            
        }
    }
    CustomEditor "FxStandardGUI"
}
