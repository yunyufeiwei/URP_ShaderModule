Shader "Unlit/QJNN/Cubemap" {
    Properties {
        _MainColor("MainColor" , Color) = (1,1,1,1)
        _CubeMap ("CubeMap", Cube) = "_Skybox" {}
        _CubeMapIntensity ("CubeMapIntensity",Range(0,1)) = 1
        _Specular ("Specular", Range(0, 1)) = 0
        _Gloss ("Gloss", Range(0, 1)) = 0
        _Alpha("Alpha",Range(0,1)) = 1
        _WorldSpaceDir("Dir",Vector) = (1,1,1,1)
        _WorldSpaceDir2("Dir2",Vector) = (1,1,1,1)

    }
    SubShader {
        Tags {
            "RenderType"="Transparent" "Queue" = "Transparent"
        }
        LOD 100
        Blend One OneMinusSrcAlpha
        Pass {
            Tags {
                "LightMode"="ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma multi_compile_fog
            #pragma target 3.0
            float4 _LightColor0;
            samplerCUBE _CubeMap;
            fixed4 _MainColor,_WorldSpaceDir,_WorldSpaceDir2;
            fixed _Specular,_Gloss,_CubeMapIntensity,_Alpha;

            struct VertexInput {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 posWorld : TEXCOORD0;
                float3 normalDir : TEXCOORD1;
                LIGHTING_COORDS(2,3)
                UNITY_FOG_COORDS(4)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID( v );
                UNITY_TRANSFER_INSTANCE_ID( v, o );
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                float3 lightColor = _LightColor0.rgb;
                o.pos = UnityObjectToClipPos( v.vertex );
                UNITY_TRANSFER_FOG(o,o.pos);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
                UNITY_SETUP_INSTANCE_ID( i );
                i.normalDir = normalize(i.normalDir);
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 normalDirection = i.normalDir;
                float3 viewReflectDirection = reflect( -viewDirection, normalDirection );
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                float3 lightColor = _LightColor0.rgb;
                float3 halfDirection = normalize(viewDirection+_WorldSpaceDir);
                float3 halfDirection2 = normalize(viewDirection+_WorldSpaceDir2);

////// Lighting:
                float attenuation = LIGHT_ATTENUATION(i);
                float3 attenColor = attenuation * _LightColor0.xyz;
///////// Gloss:
                float _Gloss_var = UNITY_ACCESS_INSTANCED_PROP( Props, _Gloss );
                float gloss = _Gloss_var;
                float specPow = exp2( gloss * 10.0 + 1.0 );
////// Specular:
                float NdotL = saturate(dot( normalDirection, lightDirection ));
                float _Specular_var = UNITY_ACCESS_INSTANCED_PROP( Props, _Specular );
                float3 specularColor = float3(_Specular_var,_Specular_var,_Specular_var);
                float specularMonochrome = max( max(specularColor.r, specularColor.g), specularColor.b);
                float normTerm = (specPow + 8.0 ) / (8.0 * 3.1415926);
                float3 specular = attenColor * pow(max(0,dot(halfDirection,normalDirection)),specPow)*normTerm*specularColor;
                float3 specular2 = attenColor * pow(max(0,dot(halfDirection2,normalDirection)),specPow)*normTerm*specularColor;

/////// Diffuse:
                NdotL = saturate(dot( normalDirection, lightDirection ));
                float3 directDiffuse =  NdotL * attenColor;
                float3 indirectDiffuse = UNITY_LIGHTMODEL_AMBIENT.rgb; // Ambient Light

                float3 CubeMapVar = texCUBE(_CubeMap,viewReflectDirection).rgb*_CubeMapIntensity;
                float3 diffuse = ((directDiffuse + indirectDiffuse) + CubeMapVar)*_MainColor.rgb+specular+specular2;
                
                fixed4 OutC = fixed4(diffuse,_Alpha);
                UNITY_APPLY_FOG(i.fogCoord, OutC);
                return OutC;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
