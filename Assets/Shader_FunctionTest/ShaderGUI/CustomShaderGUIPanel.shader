Shader "Art_URP/FunctionTest/CustomShaderGUIPanel"
{
    Properties
    {
        [Header(Float)]
        _Float("float",float) = 0
        _Range("Range",Range(0,5)) = 1

        [Header(Vector)]
        _Vector("vector",vector) = (0,0,0,0)

        [Header(Color)]
        _Color("Color" , Color)=(1,1,1,1)
        _BaseMap ("BaseMap", 2D) = "white"{}

        [Header(bool)]
        _SaveValue01("SaveValue",vector)=(0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" "IgnoreProjector" = "True"}
        LOD 100

        Pass
        {
            Name "Unlit"
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile _ _VECTORENABLED_ON

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 texcoord   : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
                float  fogCoord    : TEXCOORD1;
            };

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);        
            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _Color;
            float  _Float;
            float  _Range;
            float4 _Vector;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o;

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);

                o.fogCoord = ComputeFogFactor(o.positionHCS.z);

                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;
                half4 BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap , i.uv);

                half4 color = BaseMap * _Color;
                
                FinalColor.rgb = MixFog(color.rgb , i.fogCoord);

                return BaseMap;
                // return FinalColor;
            }
            ENDHLSL
        }
    }
    CustomEditor "CustomShaderGUI"
}
