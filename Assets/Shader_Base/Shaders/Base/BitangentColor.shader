Shader "Art_URP/Base/BitangentColor"
{
    Properties
    {
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
            
            struct Attributes
            {
                float4 positionOS     : POSITION;
                float3 normalOS       : NORMAL;
                float4 tangentOS      : TANGENT;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 color        : TEXCOORD;
                float3 normalColor  : TEXCOORD1;
                float3 tangentColor : TEXCOORD2;
            };
            
            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);

                o.normalColor = v.normalOS.xyz;
                o.tangentColor  = v.tangentOS.xyz;

                //GetOddNegativeScale()方法路径：Library\PackageCache\com.unity.render-pipelines.core@12.1.8\ShaderLibrary\SpaceTransforms.hlsl
                //v.tangentOS.xyz是切线方向,v.tangent.w的值为+1或者-1，该分量进一步决定了取叉乘结果的正方向还是反方向
                float sign = GetOddNegativeScale() * v.tangentOS.w;
                half3 bitangentColor = cross(o.normalColor,o.tangentColor) * sign;
                o.color = bitangentColor;

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;
                FinalColor = half4(i.color,1);

                return FinalColor;
            }
            ENDHLSL  
        }
    }
}
