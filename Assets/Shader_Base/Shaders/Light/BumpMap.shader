Shader "Art_URP/Base/Light/BumpMap"
{
    Properties
    {
        _BumpMap("BumpMap" , 2D) = "bump"{}
        _BumpScale("BumpScale",float) = 1
        _SpecularColor("SpecularColor" , Color) = (1,1,1,1)
        [PowerSlider(20)]_SpecularGloss("SpecularGloss" , Range(8,255)) = 20
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}

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
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;

            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD;
                float3 normalWS     : TEXCOORD1;
                float3 tangentWS    : TEXCOORD2;
                float3 bitangentWS  : TEXCOORD3;
                float3 viewWS       : TEXCOORD4;
            };
            
            TEXTURE2D(_BumpMap);SAMPLER(sampler_BumpMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BumpMap_ST;
                float  _BumpScale;
                float4 _SpecularColor; 
                float  _SpecularGloss;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                
                //世界空间下的法线相关数据信息
                o.normalWS = normalize(TransformObjectToWorldNormal(v.normalOS));
                o.tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);
                half signDir = real(v.tangentOS.w) * GetOddNegativeScale();
                o.bitangentWS =cross(o.normalWS , o.tangentWS) * signDir;    

                //世界空间下的视角向量
                o.viewWS = GetWorldSpaceViewDir(positionWS);

                o.uv = TRANSFORM_TEX(v.texcoord , _BumpMap);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;
                //光照相关数据
                Light light  = GetMainLight();
                half3 lightColor = light.color * light.distanceAttenuation;
                half3 lightDir   = light.direction;
                half3 ambientColor = _GlossyEnvironmentColor.xyz;      //当环境光使用Color模式的时候，效果会比较明显。这里判断unity_AmbientSky.rgb可能是作用在颜色上的

                //法线数据提取
                half4 bumpMap = SAMPLE_TEXTURE2D(_BumpMap,sampler_BumpMap , i.uv);
                //纹理贴图存储的是切线空间下的信息，使用UnpackNormalScale解包出来的也是切线空间下的法线信息
                half3 normalTS = UnpackNormalScale(bumpMap , _BumpScale);
                //把UnpackNormal得到的法线从切线空间转换到世界空间
                //使用TBN矩阵，将法线信息从切线空间转换到世界空间,使用TransformTangentToWorld()方法进行变换，如要传入normalTS(切线空间的法线)，以及3x3的TBN矩阵
                //使用计算的世界空间数据构建TBN矩阵---worldNormalDir = tangentNormalDir * float3x3(tangentWS.xyz , bitangentWS.xyz , normalWS.xyz);
                half3 worldNormalDir = normalize(TransformTangentToWorld(normalTS , float3x3(i.tangentWS.xyz , i.bitangentWS.xyz , i.normalWS.xyz) , true));

                half3 viewWS = SafeNormalize(i.viewWS);

                half3 diffuseColor = LightingLambert(lightColor , lightDir , worldNormalDir);
                half3 specularColor = LightingSpecular(lightColor , lightDir , worldNormalDir ,viewWS , _SpecularColor , _SpecularGloss);

                FinalColor = half4(diffuseColor + specularColor + ambientColor , 1);
                
                // return half4(normalTS,1);
                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
