Shader "Art_URP/FunctionTest/InteriorMappingCubeMap"
{
    Properties
    {
        _Cube ("Cube", Cube) = "" { }
        _Tilling ("Tilling", Float) = 1.0
        _Angle ("Angle", Float) = 1.0
        _RotateAxis ("RotateAxis", Vector) = (0, 0, 1, 1)
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" }
        LOD 100
        
        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/ShaderLibs/Node.hlsl"

            struct a2v
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
            };
            struct v2f
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3x3 tbnMtrix : float3x3;
            };

            TEXTURECUBE(_Cube);SAMPLER(sampler_Cube);
            CBUFFER_START(UnityPerMaterial)
                float _Tilling;
                float _Angle;
                float3 _RotateAxis;
            CBUFFER_END
            v2f vert(a2v v)
            {
                v2f o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);

                half3 worldNormal = TransformObjectToWorldNormal(v.normalOS);
                half3 worldTangent = TransformObjectToWorldDir(v.tangentOS.xyz);
                half3 worldBinormal = cross(worldNormal, worldTangent) * v.tangentOS.w;
                
                o.tbnMtrix = float3x3(worldTangent, worldBinormal, worldNormal);

                o.uv = v.texcoord;
                
                return o;
            }
         
            half4 frag(v2f i) : SV_Target
            {
                float3 V = SafeNormalize(GetWorldSpaceViewDir(i.positionWS));

                float3 viewTS = normalize(mul(i.tbnMtrix, V));

                float3 interuvw = InteriorCubemap(i.uv, _Tilling, viewTS);
                interuvw = RotateAboutAxis_Degrees(interuvw, _RotateAxis, _Angle);
                float3 color = SAMPLE_TEXTURECUBE(_Cube, sampler_Cube , interuvw).rgb;

                return half4(color, 1.0);
            }
            ENDHLSL
        }
    }
}