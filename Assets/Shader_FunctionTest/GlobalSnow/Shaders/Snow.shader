Shader "Art_URP/FunctionTest/Snow"
{
    Properties
    {
		_Color("Color",Color) = (1,1,1,1)
        _BaseMap ("BaseMap", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "white"{}
		_BumpScale("BumpScale",float) = 0.1
		_Step("Step",Range(1,30)) = 1
		_ToonEffect("ToonEffect",Range(0,1)) = 0.5
		
		[Header(Snow)]
		_SnowColor("SnowColor", Color) = (1,1,1,1)
		_SnowDir("SnowDir", Vector) = (0,1,0)
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag			
			
			#pragma multi_compile __ SNOW_ON

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS     : POSITION;
				float2 texcoord		  : TEXCOORD;
                float3 normalOS       : NORMAL;
				float4 tangentOS    : TANGENT;
            };

			struct Varyings
            {
                float4 positionHCS : SV_POSITION;
				float4 uv : TEXCOORD0;
				float4 TtoW0 : TEXCOORD1;
				float4 TtoW1 : TEXCOORD2;
				float4 TtoW2 : TEXCOORD3;
				float3 viewWS       : TEXCOORD4;
            };

			TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
			TEXTURE2D(_BumpMap);SAMPLER(sampler_BumpMap);

			CBUFFER_START(UnityPerMaterial)
				half4 _Color;
				float4 _BaseMap_ST;
				float4 _BumpMap_ST;
				float _BumpScale;
				float _Step;
				float _ToonEffect;
				float _Snow;
				float4 _SnowColor;
				float4 _SnowDir;
			CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _BaseMap);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

				half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
				half3 worldNormal = TransformObjectToWorldNormal(v.normalOS.xyz);
				half3 worldTangent = TransformObjectToWorldDir(v.tangentOS.xyz);
				half3 worldBinormal = cross(worldNormal,worldTangent) * v.tangentOS.w;

				o.TtoW0 = float4(worldTangent.x , worldBinormal.x , worldNormal.x , positionWS.x);
				o.TtoW1 = float4(worldTangent.y , worldBinormal.y , worldNormal.y , positionWS.y);
				o.TtoW2 = float4(worldTangent.z , worldBinormal.z , worldNormal.z , positionWS.z);
                
				o.viewWS = GetWorldSpaceViewDir(positionWS);

                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
				half4 FinalColor;

				Light light  = GetMainLight();
                half3 lightColor = light.color * light.distanceAttenuation;
                half3 lightDir   = light.direction;

                half3 ambientColor = _GlossyEnvironmentColor.xyz;

				//计算向量
				half3 viewDir = SafeNormalize(i.viewWS);
				// float3 positionWS = float3(i.TtoW0.w, i.TtoW1.w,i.TtoW2.w);

				half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap , sampler_BaseMap , i.uv);
				half4 packedNormal = SAMPLE_TEXTURE2D(_BumpMap,sampler_BumpMap,i.uv.zw);
				half3 normalDirTS = UnpackNormal(packedNormal);
				normalDirTS.xy *= _BumpScale;
				half3 worldNormal = normalize(float3(dot(i.TtoW0.xyz, normalDirTS), dot(i.TtoW1.xyz, normalDirTS),dot(i.TtoW2.xyz,normalDirTS)));

				half halfLambert = dot(lightDir,worldNormal) * 0.5 + 0.5;
				halfLambert = smoothstep(0,1,halfLambert);
				float toon = floor(halfLambert * _Step)/_Step;
				halfLambert = lerp(halfLambert,toon,_ToonEffect);
				
				half4 diffuse = half4(lightColor.rgb * baseMap.rgb * _Color.rgb * halfLambert , 1.0);

				#if SNOW_ON
					if(dot(worldNormal,_SnowDir.xyz) > lerp(1,-1,_Snow))
					{
						diffuse.rgb = _SnowColor.rgb;
					}
				else
					{
						diffuse.rgb = diffuse.rgb;
					}
                #endif

                return diffuse;
            }
            ENDHLSL
        }
    }
}
