Shader "Unlit/Eye" {
    Properties {
        _MainTexture ("MainTexture", 2D) = "white" {}
        _GlossRange ("GlossRange", Range(0, 1)) = 0.6813079
        _GlossColor ("GlossColor", Color) = (0.5,0.5,0.5,1)
        _GlossIntensity ("GlossIntensity", Range(0, 20)) = 1
        _GlossMask ("GlossMask", 2D) = "white" {}
        _StarMask ("StarMask" , 2D) = "black"{}
        _StarPower ("StarPower" ,Range(0,50)) = 1
        _StarColor("StarColor",Color) = (1,1,1,1)
        _StarTime("StarTime",Range(0.1,5)) = 1
    }
    SubShader {
        Pass {
            Tags {
            "RenderType"="Opaque"
                "Queue"="Geomentry" 
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
            sampler2D _MainTexture; 
            fixed4 _MainTexture_ST;
            sampler2D _GlossMask,_StarMask; 
            fixed4 _GlossMask_ST,_StarMask_ST;
            fixed _GlossRange,_GlossIntensity,_StarPower;
            fixed4 _GlossColor;
            fixed4 _StarColor;
            fixed _StarTime;

            struct VertexInput {
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float2 uv : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                LIGHTING_COORDS(3,4)
                UNITY_FOG_COORDS(5)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID( v );
                UNITY_TRANSFER_INSTANCE_ID( v, o );
                o.uv = v.uv;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
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
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                float3 halfDirection = normalize(viewDirection+lightDirection);
                float4 _MainTexture_var = tex2D(_MainTexture,TRANSFORM_TEX(i.uv, _MainTexture));
                float3 emissive = _MainTexture_var.rgb;
                float4 _GlossMask_var = tex2D(_GlossMask,TRANSFORM_TEX(i.uv, _GlossMask));
                float4 _StartMask_var = tex2D(_StarMask,TRANSFORM_TEX(i.uv, _StarMask));
                fixed timescale = frac(_Time.x*_StarTime);
                half2 startuv = (half2(i.uv.x+timescale,i.uv.y+timescale));
                float4 _StartMask_var2 = tex2D(_StarMask,TRANSFORM_TEX(startuv, _StarMask));
                fixed3 GlossVar = (pow(max(0,dot(normalDirection,halfDirection)),exp2(((_GlossRange*10.0)+1.0)))*_GlossColor.rgb*_GlossIntensity*_GlossMask_var.r);
                float3 ColorVar = emissive + (_MainTexture_var.rgb*GlossVar)+((_StartMask_var.rrr*_StartMask_var2.g)*_StarColor.rgb*_GlossMask_var.r*_StarPower);
                fixed4 OutC = fixed4(ColorVar,1);
                UNITY_APPLY_FOG(i.fogCoord, OutC);
                return OutC;
            }
            ENDCG
        }
    }
    FallBack "VertexLit"
}
