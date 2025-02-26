Shader "Art_URP/FunctionTest/WaterBottle"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _TopColor("Top Color", Color) = (1,1,1,1)
        _FoamColor("Foam Color", Color) = (1,1,1,1)
        _FluidHeight("Fluid Height", Range(-0.5, 0.5)) = 0
        _Threshold("Threshold", Range(0, 1)) = 0.1
        _DepthMaxDistance("Foam Distance", Range(0,2)) = 1


        [HideInInspector]_WobbleX("MaxHeightInX", Float) = 0
        [HideInInspector]_WobbleZ("MaxHeightInZ", Float) = 0

        _LiquidRimColor ("Liquid Rim Color", Color) = (1,1,1,1)
        _LiquidRimPower ("Liquid Rim Power", Range(0,50)) = 0
        _LiquidRimScale ("Liquid Rim Scale", Range(0,1)) = 1

        [Header(Bottle)]

        _BottleColor ("Bottle Color", Color) = (0.5,0.5,0.5,1)
        _BottleThickness ("Bottle Thickness", Range(0,1)) = 0.1
        
        _BottleRimColor ("Bottle Rim Color", Color) = (1,1,1,1)
        _BottleRimPower ("Bottle Rim Power", Range(0,10)) = 0.0
        _BottleRimIntensity ("Bottle Rim Intensity", Range(0.0,3.0)) = 1.0
        
        _BottleSpecular ("Bottle Specular Color", Color) = (1,1,1,1)
        _BottleGloss ("BottleGloss", Range(0,1) ) = 0.5
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalRenderPipeline" "Queue"="Transparent" "RenderType"="Transparent"}

        Pass
        {
            Tags{"LightMode" = "SRPDefaultUnlit"}
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float4 pos : SV_POSITION;	
                float3 normal : TEXCOORD0;
                float3 viewDir : COLOR;
                float3 localPos : COLOR2;
                float4 screenPos : TEXCOORD1;
            };


            TEXTURE2D(_CameraDepthTexture);SAMPLER(sampler_CameraDepthTexture);
            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
                half4 _TopColor;
                half4 _FoamColor;
                half _FluidHeight;
                half _Threshold;
                float _WobbleX;
                float _WobbleZ;
                float _LiquidRimPower;
                float _LiquidRimScale;
                half4 _LiquidRimColor;
                half _DepthMaxDistance;
            CBUFFER_END
            
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                float rate = sqrt((0.5 * 0.5 - _FluidHeight * _FluidHeight) / (v.positionOS.x * v.positionOS.x + v.positionOS.z * v.positionOS.z));
                float vertexDis = min(rate, 1);
                half vertexHeight = step(_FluidHeight, v.positionOS.y);
                v.positionOS.y = vertexHeight * _FluidHeight + (1 - vertexHeight) * v.positionOS.y;
                v.normalOS = vertexHeight * half3(0, 1, 0) + (1 - vertexHeight) * v.normalOS;

                // 等同于下面的if分支
                vertexDis = lerp(1,vertexDis,vertexHeight);
                v.positionOS.xz *= vertexDis;
                float isRate = (rate - 1 < _Threshold && rate - 1 > 0);
                isRate *= vertexHeight;
                rate = lerp(1,rate,isRate);
                v.positionOS.xz *= rate;
                // if (vertexHeight == 1)
                // {
                //         if (rate - 1 < _Threshold && rate - 1 > 0)
                //         v.vertex.xz *= rate;
                //         v.vertex.xz *= vertexDis;
                // }

                float X, Z;
                X = atan(_WobbleZ / 2);
                Z = atan(_WobbleX / 2);
                float3x3 rotMatX, rotMatZ;
                rotMatX[0] = float3(1, 0, 0);
                rotMatX[1] = float3(0, cos(X), sin(X));
                rotMatX[2] = float3(0, -sin(X), cos(X));
                rotMatZ[0] = float3(cos(Z), sin(Z), 0);
                rotMatZ[1] = float3(-sin(Z), cos(Z), 0);
                rotMatZ[2] = float3(0, 0, 1);
                v.positionOS.xyz = mul(rotMatX, mul(rotMatZ, v.positionOS.xyz));
                o.pos = TransformObjectToHClip(v.positionOS.xyz);
                o.localPos = v.positionOS;
                o.normal = v.normalOS;
                o.viewDir = GetWorldSpaceViewDir(TransformObjectToWorld(v.positionOS.xyz));
                o.screenPos.xyz = TransformWorldToView(TransformObjectToWorld(v.positionOS.xyz));
                return o;
            }
            half4 frag(Varyings i) : SV_Target
            {
                // 获取屏幕深度
                half existingDepth01 = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture ,i.screenPos).r;
                half existingDepthLinear = LinearEyeDepth(existingDepth01 , _ZBufferParams);
                half depthDifference = existingDepthLinear - i.screenPos.w;
                // 泡沫
                half waterDepthDifference01 = saturate(depthDifference / _DepthMaxDistance);
                float4 topColor = lerp(_FoamColor, _TopColor, waterDepthDifference01);

                float3 N = normalize(i.normal);
                float3 V = normalize(i.viewDir);
                float NdotV = max(0,dot(N, V));

                half fresnel = _LiquidRimScale + (1 - _LiquidRimScale) * pow(1 - NdotV, _LiquidRimPower);
                half4 color = lerp(_Color,_LiquidRimColor,fresnel);
                topColor = lerp(topColor,_LiquidRimColor,fresnel);

                color.a += fresnel;

                half isTop = i.normal.y > 0.99;

                return lerp(color,topColor,isTop);
            }
            ENDHLSL
        }

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            Blend SrcAlpha OneMinusSrcAlpha
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma enable_d3d11_debug_symbols

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
                float3 normalOS     : NORMAL; 
            };
            
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 viewDirWS    : COLOR;
                float3 normalWS     : COLOR2;
                float2 uv           : TEXCOORD0;
                float3 lightDir     : TEXCOORD1;
                float3 normalDir    : TEXCOORD2;
                float3 viewDirWorld : TEXCOORD3;
            };

            CBUFFER_START(UnityPerMateiral)
            float4 _BottleColor;
            float4 _BottleRimColor;
            float4 _BottleSpecular;
            float _BottleThickness;
            float _BottleRim;
            float _BottleRimPower;
            float _BottleRimIntensity;
            float _BottleGloss;
            float _SpecularThreshold;
            float _SpecularSmoothness;
            CBUFFER_END
            
            Varyings vert (Attributes v)
            {
                Varyings o = ( Varyings)0;
                v.positionOS.xyz += _BottleThickness * v.normalOS;
                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);

                o.viewDirWS = GetWorldSpaceViewDir(positionWS);
                o.normalWS = v.normalOS;
                
                o.normalDir = TransformObjectToWorldNormal(v.normalOS);
                o.lightDir = _MainLightPosition.xyz;
                return o;
            }
            
            // 计算色阶
            float calculateRamp(float threshold,float value, float smoothness){
                threshold = saturate(1-threshold);
                half minValue = saturate(threshold - smoothness);
                half maxValue = saturate(threshold + smoothness);
                return smoothstep(minValue,maxValue,value);
            }

            half4 frag (Varyings i, half facing : VFACE) : SV_Target
            {
                // specular
                float3 N = normalize(i.normalDir);
                float3 V = normalize(i.viewDirWS);
                float specularPow = exp2 ((1 - _BottleGloss) * 10.0 + 1.0);
                
                float3 H = normalize (i.lightDir + i.viewDirWS);
                float NdotH = max(0,dot(N, H));
                float NdotV = max(0,dot(N, V));

                half specularCol = pow(NdotH,specularPow)*_BottleSpecular;
                // 阈值判断
                // float specularRamp = calculateRamp(_SpecularThreshold,specular,_SpecularSmoothness);
                // half4 specularCol = specularRamp*_BottleSpecular;

                // rim
                float fresnel = 1 - pow(NdotV, _BottleRimPower);
                half4 rim = _BottleRimColor * smoothstep(0.5, 1.0, fresnel) * _BottleRimIntensity;
                rim.rgb = rim.a > 0.25 ? _BottleColor.rgb : rim.rgb;

                half4 finalCol = rim + _BottleColor + specularCol;
                return finalCol;
            }
            ENDHLSL
        }	
    }
}
