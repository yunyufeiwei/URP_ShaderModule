//奇技淫巧
#ifndef PBRMath
    #define PBRMath
 
            // 直接光照 D项 法线微表面分布函数
            half Direct_D_Function(half NdotH, half roughness)
            {
                half a2 = Pow4(roughness);
                half d = (NdotH * NdotH * (a2 - 1.0) + 1.0);
                d = d * d;// *PI;
                return saturate(a2 / d);
            }
 
            // method1:
            // 直接光照 F项
            half3 Direct_F_Function(half HdotL, half3 F0)
            {
                half Fre = exp2((-5.55473 * HdotL - 6.98316) * HdotL);
                return lerp(Fre, 1, F0);
            }
 
            // // method2:
            // // 直接光照 F项
            // half3 Direct_F_Function(half HdotL, half3 F0)
            // {
                //     half Fre = pow(1 - HdotL, 5);
                //     return lerp(Fre, 1, F0);
            // }
 
            inline half3 Direct_F0_Function(half3 albedo, half metallic)
            {
                return lerp(0.04, albedo, metallic);
            }
 
            // 直接光照 G项子项
            inline real Direct_G_subSection(half dot, half k)
            {
                return dot / lerp(dot, 1, k);
            }
            // 直接光照 G项
            half Direct_G_Function(half NdotL, half NdotV, half roughness)
            {
                // method1-k:
                // // half k = pow(1 + roughness, 2) / 8.0;
 
                // // method2-k:
                // const half d = 1.0 / 8.0;
                // half k = pow(1 + roughness, 2) * d;
 
                // method3-k:
                half k = pow(1 + roughness, 2) * 0.5;
                return Direct_G_subSection(NdotL, k) * Direct_G_subSection(NdotV, k);
            }
 
            // 模拟 G项:Kelemen-Szirmay-Kalos Geometry Factor
            inline half Direct_G_Function_Kalos(half LdotH, half roughness)
            {
                half k = pow(1 + roughness, 2) * 0.5;
                return Direct_G_subSection(LdotH, k);
            }
            //间接漫反射函数
            real3 SH_IndirectionDiff(real3 normalWS)
            {
                real4 SHCoefficients[7];
                SHCoefficients[0] = unity_SHAr;
                SHCoefficients[1] = unity_SHAg;
                SHCoefficients[2] = unity_SHAb;
                SHCoefficients[3] = unity_SHBr;
                SHCoefficients[4] = unity_SHBg;
                SHCoefficients[5] = unity_SHBb;
                SHCoefficients[6] = unity_SHC;
                real3 color = SampleSH9(SHCoefficients, normalWS);
                return max(0, color);
            }
            //间接镜面反射函数
            half3 Indirect_F_Function(half NdotV, half3 F0, half roughness)
            {
                half fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV);
                return F0 + fre * saturate(1 - roughness - F0);
            }
 
            half3 IndirectSpeCube(half3 normalWS, half3 viewWS, float roughness, half AO)
            {
                half3 reflectDirWS = reflect(-viewWS, normalWS);
                roughness = roughness * (1.7 - 0.7 * roughness); // unity 内部不是线性 调整下 拟合曲线求近似，可以再 GGB 可视化曲线
                half mipmapLevel = roughness * 6; // 把粗糙度 remap 到 0~6 的 7个阶段，然后进行 texture lod 采样
                half4 specularColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDirWS, mipmapLevel); // 根据不同的 mipmap level 等级进行采样
                #if !defined(UNITY_USE_NATIVE_HDR)
                // 用 DecodeHDREnvironment 将解码 HDR 颜色值。
                // 可以看到采样出的 RGBM 是一个 4 通道的值
                // 最后的一个 M 存的是一个参数
                // 解码时将前三个通道表示的颜色乘上 x*(M^y)
                // x y 都是有环境贴图定义的系数
                // 存储在 unity_SpecCube0_HDR 这个结构中
                return DecodeHDREnvironment(specularColor, unity_SpecCube0_HDR) * AO;
                #else
                return specularColor.rgb * AO;
                #endif
            }
 
                half3 IndirectSpeFactor(half roughness, half smoothness, half3 BRDFspe, half3 F0, half NdotV)
                {
                    #ifdef UNITY_COLORSPACE_GAMMA
                    half SurReduction = 1 - 0.28 * roughness * roughness;
                    #else
                    half SurReduction = 1 / (roughness * roughness + 1);
                    #endif
                    #if defined(SHADER_API_GLES) // Lighting.hlsl 261 行
                    half Reflectivity = BRDFspe.x;
                    #else
                    half Reflectivity = max(max(BRDFspe.x, BRDFspe.y), BRDFspe.z);
                    #endif
                    half GrazingTSection = saturate(Reflectivity + smoothness);
                    half fre = Pow4(1 - NdotV); // Lighting.hlsl 第 501 行
                    // half fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV); // Lighting.hlsl 第 501 行，他是 4 次方，我们是 5 次方
                    return lerp(F0, GrazingTSection, fre) * SurReduction;
                }
 
 
 
#endif