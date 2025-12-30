//对照photoshop的混合形式，定义相应的混合算法

#ifndef COLORBLENDMODE_INCLUDED
#define COLORBLENDMODE_INCLUDED
//变暗
float3 Darken(float3 Src, float3 Dst)
{
    return saturate(min(Src.rgb, Dst.rgb));
}

//正片叠底
float3 Multiply(float3 Src, float3 Dst)
{
    return saturate((Src.rgb*Dst.rgb));
}

//Color Burn颜色加深
float3 ColorBurn(float3 Src, float3 Dst) {
    return saturate((1.0-((1.0-Dst.rgb)/Src.rgb)));
}

//Linear Burn线性加深
float3 LinearBurn(float3 Src, float3 Dst) {
    return saturate((Src.rgb+Dst.rgb-1.0));
}

//Lighten变亮
float3 Lighten(float3 Src, float3 Dst) {
    return saturate(max(Src.rgb,Dst.rgb));
}

//Screen滤色
float3 Screen(float3 Src, float3 Dst) {
    return saturate((1.0-(1.0-Src.rgb)*(1.0-Dst.rgb)));
}

//Color Dodge颜色减淡
float3 ColorDodge(float3 Src, float3 Dst) {
    return saturate((Dst.rgb/(1.0-Src.rgb)));
}

//Linear Dodge线性减淡
float3 LinearDodge(float3 Src, float3 Dst) {
    return saturate((Src.rgb+Dst.rgb));
}

//Overlay叠加
float3 Overlay(float3 Src, float3 Dst) {
    return saturate(( Dst.rgb > 0.5 ? (1.0-(1.0-2.0*(Dst.rgb-0.5))*(1.0-Src.rgb)) : (2.0*Dst.rgb*Src.rgb) ));
}

//Hard Light强光
float3 HardLight(float3 Src, float3 Dst) {
    return saturate((Src.rgb > 0.5 ?  (1.0-(1.0-2.0*(Src.rgb-0.5))*(1.0-Dst.rgb)) : (2.0*Src.rgb*Dst.rgb)) );
}

//Vivid Light亮光
float3 VividLight(float3 Src, float3 Dst) {
    return saturate(( Src.rgb > 0.5 ? (Dst.rgb/((1.0-Src.rgb)*2.0)) : (1.0-(((1.0-Dst.rgb)*0.5)/Src.rgb))));
}

//Linear Light线性光
float3 LinearLight(float3 Src, float3 Dst) {
    return saturate(( Src.rgb > 0.5 ? (Dst.rgb + 2.0*Src.rgb -1.0) : (Dst.rgb + 2.0*(Src.rgb-0.5))));
}

//Pin Light点光
float3 PinLight(float3 Src, float3 Dst) {
    return saturate(( Src.rgb > 0.5 ? max(Dst.rgb,2.0*(Src.rgb-0.5)) : min(Dst.rgb,2.0*Src.rgb) ));
}

//Hard Mix实色混合
float3 HardMix(float3 Src, float3 Dst) {
    return saturate(round( 0.5*(Src.rgb + Dst.rgb)));
}

//Difference差值
float3 Difference(float3 Src, float3 Dst) {
    return saturate(abs(Src.rgb-Dst.rgb));
}

//Exclusion排除
float3 Exclusion(float3 Src, float3 Dst) {
    return saturate((0.5 - 2.0*(Src.rgb-0.5)*(Dst.rgb-0.5)));
}

//Subtract减去
float3 Subtract(float3 Src, float3 Dst) {
    return saturate((Dst.rgb-Src.rgb));
}

//Divide划分
float3 Divide(float3 Src, float3 Dst) {
    return saturate((Dst.rgb/Src.rgb));
}
#endif