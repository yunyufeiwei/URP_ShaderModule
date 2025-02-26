Shader "Art_URP/FunctionTest/InteriorMapping2DAtlas"
{
    Properties
    {
        _RoomTex ("Room Atlas RGB (A - back wall depth01)", 2D) = "gray" { }
        [Toggle(_USE_ATLAS)] _USE_ATLAS ("Use Atlas", float) = 0
        [ShowIf(_USE_ATLAS)]_Rooms ("Room Count(X count,Y count,Z seed)", vector) = (1, 1, 0, 0)
        _RoomMaxDepth01 ("Room Max Depth define(0 to 1)", range(0.001, 0.999)) = 0.5
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
            #pragma shader_feature_fragment _ _USE_ATLAS

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/ShaderLibs/Node.hlsl"
            #include "Assets/ShaderLibs/Noise.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 viewTS       : TEXCOORD1;
            };

            TEXTURE2D(_RoomTex);SAMPLER(sampler_RoomTex);
            CBUFFER_START(UnityPerMaterial)
                float4 _RoomTex_ST;
                float4 _Rooms;
                float _RoomMaxDepth01;
            CBUFFER_END
            
            Varyings vert(Attributes v)
            {
                Varyings o=(Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);

                //find view dir OS
                float3 camPosOS = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0)).xyz;
                float3 viewDirOS = v.positionOS.xyz - camPosOS;

                // get tangent space view vector
                o.viewTS = ObjectToTangentDir(viewDirOS, v.normalOS, v.tangentOS);

                o.uv = TRANSFORM_TEX(v.texcoord, _RoomTex);
                
                return o;
            }
            
            half4 frag(Varyings i) : SV_Target
            {
                // room uvs
                float2 roomUV = frac(i.uv);
                float2 roomIndexUV = floor(i.uv);

                #if defined(_USE_ATLAS)
                    // randomize the room
                    float2 n = floor(random2(roomIndexUV.x + roomIndexUV.y * (roomIndexUV.x + 1) + _Rooms.z) * _Rooms.xy);
                    roomIndexUV += n; //colin: result = index XY + random (0,0)~(3,1)
                #endif

                float2 interiorUV = ConvertOriginalRawUVToInteriorUV(roomUV, i.viewTS, _RoomMaxDepth01);
                half4 room = SAMPLE_TEXTURE2D(_RoomTex, sampler_RoomTex , (roomIndexUV + interiorUV) / _Rooms.xy);

                return half4(room.rgb, 1.0);
            }
            ENDHLSL
        }
    }
}
