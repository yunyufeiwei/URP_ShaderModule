//https://catlikecoding.com/unity/tutorials/flow/waves/#1
Shader "Art_URP/FunctionTest/OpaqueColor"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _SpecularColor("SpecularColor",Color) = (1,1,1,1)
        _Roughness("Roughness",Float) = 1
        _Steepness("Steepness",Float) = 0.5
        _WaveLength("WaveLength",Float) = 10
        //_Speed("Speed",Float) = 1
        _WaveA ("Wave A (dir, steepness, wavelength)", Vector) = (1,0,0.5,10)
        _WaveB ("Wave B (dir, steepness, wavelength)", Vector) = (0,1,0.25,20)
        _WaveC ("Wave C", Vector) = (1,1,0.15,10)
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry"}
        Cull Off
        LOD 100

        pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 positionWS   : TEXTOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 viewWS       : TEXCOORD2;
            };
            
            //属性定义部分
            //定义纹理采样贴图和采样状态

            //CBuffer部分，数据参数定义在该结构内，可以使用srp的batch功能
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _SpecularColor;
                float  _Roughness;
                float  _Steepness;
                float  _WaveLength;
                float  _Speed;
                float4 _WaveA;
                float4 _WaveB;
                float4 _WaveC;
            CBUFFER_END

            float3 GerstnerWave(float4 wave, float3 p, inout float3 tangent, inout float3 binormal)
            {
                float steepness = wave.z;
                float wavelength = wave.w;
                float k = 2 * PI / wavelength;
                float c = sqrt(9.8 / k);
                float2 d = normalize(wave.xy);
                float f = k * (dot(d, p.xz) - c * _Time.y);
                float a = steepness / k;
               
                tangent += float3(-d.x * d.x * (steepness * sin(f)) , d.x * (steepness * cos(f)) , -d.x * d.y * (steepness * sin(f)));
                binormal += float3(-d.x * d.y * (steepness * sin(f)) , d.y * (steepness * cos(f)) , -d.y * d.y * (steepness * sin(f)));

                return float3(d.x * (a * cos(f)) , a * sin(f) , d.y * (a * cos(f)));
            }

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                //世界空间计算
                //o.positionWS = TransformObjectToWorld(v.positionOS.xyz);

                //模型空间计算
                float3 normal = v.normalOS.xyz;
                float3 tangent = v.tangentOS.xyz;
                half sign = v.tangentOS.w * GetOddNegativeScale();
                float3 binormal = cross(tangent , normal);
                // float3 pos = o.positionWS.xyz;
                float3 pos = v.positionOS.xyz;
                pos += GerstnerWave(_WaveA, pos, tangent, binormal);
                pos += GerstnerWave(_WaveB, pos, tangent, binormal);
                pos += GerstnerWave(_WaveC, pos, tangent, binormal);

                o.normalWS = normalize(cross(binormal,tangent));

                //o.viewWS = GetWorldSpaceViewDir(o.positionWS);
                // o.positionHCS = TransformWorldToHClip(pos);
                o.viewWS = GetWorldSpaceViewDir(TransformObjectToWorld(v.positionOS.xyz));
                o.positionHCS = TransformObjectToHClip(pos);

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                Light light = GetMainLight();
                half3 lightDirection = light.direction;
                half3 worldNormal = normalize(i.normalWS);
                half3 worldViewDir = normalize(i.viewWS);
                half3 reflectDir = reflect(-lightDirection,worldNormal);

                half3 diffuse = light.color * max(0,dot(worldNormal,lightDirection));
                // half3 specular = _SpecularColor * pow(max(0,dot(reflectDir,worldViewDir)),_Roughness);
                half3 specular = _SpecularColor.xyz * pow(max(0,dot(worldNormal,normalize(lightDirection + worldViewDir))) , _Roughness);
                
                half4 color = half4(diffuse + specular , 1.0);
                return color;
            }
            ENDHLSL  
        }
    }
}
