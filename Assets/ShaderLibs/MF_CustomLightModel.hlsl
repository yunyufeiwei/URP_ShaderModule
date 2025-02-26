#ifndef MF_CUSTOMLIGHTMODEL_INCLUDED
#define MF_CUSTOMLIGHTMODEL_INCLUDED_INCLUDED

// ================================= 各向异性 Kajiya-Kay =================================
half3 ShiftTangent(half3 T, half3 N, half shift)
{
    return normalize(T + shift * N);
}

half AnisotropyKajiyaKay(half3 T, half3 V, half3 L, half specularPower)
{
    half3 H = normalize(L + V);
    half  TdotH = dot(T, H);
    half  sinTH = sqrt(1 - TdotH * TdotH);
    half  dirAtten = smoothstep(-1, 0, TdotH);
    return dirAtten * saturate(pow(sinTH, specularPower));
}

#endif