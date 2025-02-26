//https://zhuanlan.zhihu.com/p/362173018
//https://web.engr.oregonstate.edu/~mjb/cs519/Projects/Papers/HairRendering.pdf


Shader "Art_URP/Base/Light/Anisotropic"
{
    Properties
    {
        [Header(Specular)]
        _SpecularColor("SpecularColor",Color) = (1,1,1,1)
        _SpecularPower("SpecularPower" ,Range(80,1000)) = 300
        _SpecularIntensity("StretchedIntensity" , float) = 1

        [Header(Stretched)]
        _StretchedTexture("StretchedNoise",2D) = "white"{}
        _ShiftOffset("ShiftOffset",float) = 0.1
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
                float4 positionOS     : POSITION;
                float2 texcoord       : TEXCOORD;
                float3 normalOS       : NORMAL;
                float4 tangentOS      : TANGENT;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 tangentWS    : TEXCOORD2;
                float3 bitangentWS  : TEXCOORD3;
                float3 viewWS       : TEXCOORD4;
            };
            
            TEXTURE2D(_StretchedTexture);SAMPLER(sampler_StretchedTexture);
            
            CBUFFER_START(UnityPerMaterial)
                float3 _SpecularColor;
                float _SpecularPower;
                float4 _StretchedTexture_ST;
                float _SpecularIntensity;
                float _ShiftOffset;
            CBUFFER_END


            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                //GetVertexNormalInputs()方法的定义在ShaderVariablesFunctions.hlsl中,VertexNormalInputs代码表示返回该结构体内的值(通过GetVertexNormalInputs方法计算之后的)
                // VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS , v.tangentOS);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                half3 positionWS = TransformObjectToWorld(v.positionOS.xyz);

                o.normalWS = v.normalOS;
                o.tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);       //将模型的切线方向数据从模型空间转换到世界空间
                half signDir = real(v.tangentOS.w) * GetOddNegativeScale();     //通过GetOddNegativeScale()方法来得到方向的值
                o.bitangentWS =cross(o.normalWS , o.tangentWS) * signDir;       //通过法线与切线的方向叉乘，得到副法线的方向(副切线的方向有两个)，在通过上面signDir值得到需要的正确方向

                o.viewWS = GetWorldSpaceViewDir(positionWS);                  //世界空间下的视图向量
                o.uv = TRANSFORM_TEX(v.texcoord , _StretchedTexture);      //各项异性纹理贴图

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;
                //光照相关信息
                Light light = GetMainLight();
                half3 lightColor = light.color * light.distanceAttenuation;   
                half3 worldLightDir = light.direction;
                
                //向量数据相关
                half3 worldNormalDir = normalize(i.normalWS);
                half3 worldViewDir = SafeNormalize(i.viewWS);
                half3 worldTangentDir = normalize(i.tangentWS);
                half3 worldBitangentDir = normalize(i.bitangentWS);

                half3 halfDir = normalize(worldLightDir + worldViewDir);
                half  NdotH = dot(worldNormalDir,halfDir);                                                          //BlinnPhong光照模型的方式，半角向量halfDir = dot(N,H);
                half  shiftTexture = SAMPLE_TEXTURE2D(_StretchedTexture , sampler_StretchedTexture , i.uv).r;       //采样纹理的灰度(0~1)之间，在
                shiftTexture = (shiftTexture  * 2 - 1);                                                             //使用乘以2减去1将值ramp到(-1~1)之间,在额外对整体增加一个强度
                worldBitangentDir = normalize(worldBitangentDir + worldNormalDir * (_ShiftOffset + shiftTexture));  //副切线沿着法线的方向添加偏移值

                //Kajiya-Kay Model
                half  TdotH = dot(worldBitangentDir , halfDir);
                half  sinTH = sqrt(1 - TdotH * TdotH);


                half3 specularColor = pow(saturate(sinTH) , _SpecularPower) * _SpecularColor * _SpecularIntensity;

                FinalColor = half4(specularColor , 1);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
