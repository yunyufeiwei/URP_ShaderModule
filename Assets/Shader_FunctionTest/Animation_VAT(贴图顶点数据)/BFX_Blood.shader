Shader "Art_URP/FunctionTest/BFX_Blood"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
 	    _SpecColor("SpecularColor", Color) = (1,1,1,1)
        _boundingMax("Bounding Max", Float) = 1.0
        _boundingMin("Bounding Min", Float) = 1.0
        _numOfFrames("Number Of Frames", int) = 240
        _speed("Speed", Float) = 0.33
        _HeightOffset("_Height Offset", Vector) = (0, 0, 0)
        //[MaterialToggle] _pack_normal("Pack Normal", Float) = 0
        _posTex("Position Map (RGB)", 2D) = "white" {}
        _nTex("Normal Map (RGB)", 2D) = "grey" {}
        _SunPos("Sun Pos", Vector) = (1, 0.5, 1, 0)


    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "AlphaTest+1"}
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Back
        ZWrite On

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 tangent : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;

                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD2;
                float4 screenPos : TEXCOORD4;
                float3 viewDir : TEXCOORD5;
                float height : TEXCOORD6;
               // UNITY_FOG_COORDS(8)

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            TEXTURE2D(_GrabTexture);SAMPLER(sampler_GrabTexture);
            TEXTURE2D(_posTex);SAMPLER(sampler_posTex);
            TEXTURE2D(_nTex);SAMPLER(sampler_nTex);
            
            CBUFFER_START(Unity_PerMaterial)
                float _boundingMax;
                float _boundingMin;
                float _speed;
                int _numOfFrames;
                half4 _Color;
                half4 _SpecColor;
                float4 _HeightOffset;
                float _HDRFix;
                float4 _SunPos;
            CBUFFER_END

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float, _UseCustomTime)
                UNITY_DEFINE_INSTANCED_PROP(float, _TimeInFrames)
                UNITY_DEFINE_INSTANCED_PROP(float, _LightIntencity)
            UNITY_INSTANCING_BUFFER_END(Props)

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;

                // UNITY_INITIALIZE_OUTPUT(v2f, o);

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float timeInFrames;
                float currentSpeed = 1.0f / (_numOfFrames / _speed);
                timeInFrames = UNITY_ACCESS_INSTANCED_PROP(Props, _UseCustomTime) > 0.5 ? UNITY_ACCESS_INSTANCED_PROP(Props, _TimeInFrames) : 1;

                float4 texturePos = SAMPLE_TEXTURE2D_LOD(_posTex, sampler_posTex , float2(v.uv.x, (timeInFrames + v.uv.y)) , 0);
                float3 textureN = SAMPLE_TEXTURE2D_LOD(_nTex, sampler_nTex , float2(v.uv.x, (timeInFrames + v.uv.y)) , 0).rgb;

                float expand = _boundingMax - _boundingMin;
                texturePos.xyz *= expand;
                texturePos.xyz += _boundingMin;
                texturePos.x *= -1;
                v.vertex.xyz = texturePos.xzy;
                v.vertex.xyz += _HeightOffset.xyz;

                o.worldNormal = textureN.xzy * 2 - 1;
                o.worldNormal.x *= -1;
                o.viewDir = GetWorldSpaceViewDir(v.vertex.xyz);

                o.pos = TransformObjectToHClip(v.vertex.xyz);
                // o.screenPos = ComputeGrabScreenPos(o.pos);


                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                i.worldNormal = normalize(i.worldNormal);
                i.viewDir = normalize(i.viewDir);

                half fresnel = saturate(1 - dot(i.worldNormal, i.viewDir));
                half intencity = UNITY_ACCESS_INSTANCED_PROP(Props, _LightIntencity);
                half3 grabColor = intencity * 0.25;
                half light = max(0.001, dot(normalize(i.worldNormal), normalize(_SunPos.xyz)));
                light = pow(light, 50) * 10;

                grabColor *= _Color.rgb;
                grabColor = lerp(grabColor * 0.15, grabColor, fresnel);
                grabColor = min(grabColor, _Color.rgb * 0.55);

                half3 color = grabColor.xyz + saturate(light) * intencity * _SpecColor.xyz * _SpecColor.a;
                return half4(color, 1);

            }
            ENDHLSL
        }
    }
}
