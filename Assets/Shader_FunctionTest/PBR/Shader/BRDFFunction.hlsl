#ifndef BRDFFunction
    #define BRDFFunction
    //漫反射
    half3 customDisneyDiffuse(half NdotV , half NdotL , half LdotH , half roughness , half3 baseColor)
    {
        half fd90 = 0.5 + 2 * LdotH * LdotH * roughness;
        half lightScatter = 1 + (fd90 - 1) * pow((1 - NdotL) , 5);
        half viewScatter = 1 + (fd90 - 1) * pow((1  - NdotV) , 5);
        half3  denom = (baseColor * lightScatter * viewScatter) / PI;
        return denom;
    }

    //https://learnopengl-cn.github.io/07%20PBR/01%20Theory/
    //法线分布函数--D项
    float NormalDistributionFunction(half3 N , half3 H , float roughness)
    {
        float a = roughness;
        float a2 = a * a;
        float NdotH = max(dot(N,H) , 0.0);
        float NdotH2 = NdotH * NdotH;

        float nom = a2;
        float denom = (NdotH2 * (a2 - 1) + 1.0);
        denom = PI * denom * denom;
        
        return nom / denom;
    }

    //几何函数--G项
    //Schlick-Smith(1994)
    float GeometrySchlickGGX(float NdotV , float roughness)
    {
        float r = roughness + 1;
        float k = (r * r) / 8.0;
    
        float nom = NdotV;
        float denom = NdotV * (1 - k) + k;

        return nom / denom;
    }

    float GeometrySmith(float3 N,float3 V , float3 L , float roughness)
    {
        float NdotV = max(dot(N , V) , 0.0);
        float NdotL = max(dot(N , L) , 0.0);

        float ggx1 = GeometrySchlickGGX(NdotV , roughness);
        float ggx2 = GeometrySchlickGGX(NdotL , roughness);
        return ggx1 * ggx2;
    }

    //菲涅尔方程--F项
    half3 FresnelSchlick( half3 spacularColor , float NdotV)
    {
        return spacularColor + (1 - spacularColor) * pow(clamp(1 - NdotV , 0.0 , 1.0) , 5.0);
    }
#endif