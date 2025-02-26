//����photoshop�Ļ����ʽ��������Ӧ�Ļ���㷨

#ifndef COLORBLENDMODE_INCLUDED
#define COLORBLENDMODE_INCLUDED
//�䰵
float3 Darken(float3 Src, float3 Dst)
{
    return saturate(min(Src.rgb, Dst.rgb));
}

//��Ƭ����
float3 Multiply(float3 Src, float3 Dst)
{
    return saturate((Src.rgb*Dst.rgb));
}

//Color Burn��ɫ����
float3 ColorBurn(float3 Src, float3 Dst) {
    return saturate((1.0-((1.0-Dst.rgb)/Src.rgb)));
}

//Linear Burn���Լ���
float3 LinearBurn(float3 Src, float3 Dst) {
    return saturate((Src.rgb+Dst.rgb-1.0));
}

//Lighten����
float3 Lighten(float3 Src, float3 Dst) {
    return saturate(max(Src.rgb,Dst.rgb));
}

//Screen��ɫ
float3 Screen(float3 Src, float3 Dst) {
    return saturate((1.0-(1.0-Src.rgb)*(1.0-Dst.rgb)));
}

//Color Dodge��ɫ����
float3 ColorDodge(float3 Src, float3 Dst) {
    return saturate((Dst.rgb/(1.0-Src.rgb)));
}

//Linear Dodge���Լ���
float3 LinearDodge(float3 Src, float3 Dst) {
    return saturate((Src.rgb+Dst.rgb));
}

//Overlay����
float3 Overlay(float3 Src, float3 Dst) {
    return saturate(( Dst.rgb > 0.5 ? (1.0-(1.0-2.0*(Dst.rgb-0.5))*(1.0-Src.rgb)) : (2.0*Dst.rgb*Src.rgb) ));
}

//Hard Lightǿ��
float3 HardLight(float3 Src, float3 Dst) {
    return saturate((Src.rgb > 0.5 ?  (1.0-(1.0-2.0*(Src.rgb-0.5))*(1.0-Dst.rgb)) : (2.0*Src.rgb*Dst.rgb)) );
}

//Vivid Light����
float3 VividLight(float3 Src, float3 Dst) {
    return saturate(( Src.rgb > 0.5 ? (Dst.rgb/((1.0-Src.rgb)*2.0)) : (1.0-(((1.0-Dst.rgb)*0.5)/Src.rgb))));
}

//Linear Light���Թ�
float3 LinearLight(float3 Src, float3 Dst) {
    return saturate(( Src.rgb > 0.5 ? (Dst.rgb + 2.0*Src.rgb -1.0) : (Dst.rgb + 2.0*(Src.rgb-0.5))));
}

//Pin Light���
float3 PinLight(float3 Src, float3 Dst) {
    return saturate(( Src.rgb > 0.5 ? max(Dst.rgb,2.0*(Src.rgb-0.5)) : min(Dst.rgb,2.0*Src.rgb) ));
}

//Hard Mixʵɫ���
float3 HardMix(float3 Src, float3 Dst) {
    return saturate(round( 0.5*(Src.rgb + Dst.rgb)));
}

//Difference��ֵ
float3 Difference(float3 Src, float3 Dst) {
    return saturate(abs(Src.rgb-Dst.rgb));
}

//Exclusion�ų�
float3 Exclusion(float3 Src, float3 Dst) {
    return saturate((0.5 - 2.0*(Src.rgb-0.5)*(Dst.rgb-0.5)));
}

//Subtract��ȥ
float3 Subtract(float3 Src, float3 Dst) {
    return saturate((Dst.rgb-Src.rgb));
}

//Divide����
float3 Divide(float3 Src, float3 Dst) {
    return saturate((Dst.rgb/Src.rgb));
}
#endif