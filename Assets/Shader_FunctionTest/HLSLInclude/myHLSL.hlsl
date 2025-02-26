#ifndef MYHLSL_INCLUDED   
#define MYHLSL_INCLUDED    

float4 blendTex(float4 customtexture , float4 customcolor)
{
    float4 Final = customtexture * customcolor; 
    return Final;
}

#endif 

