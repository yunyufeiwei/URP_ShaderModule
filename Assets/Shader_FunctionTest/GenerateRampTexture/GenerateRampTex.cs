using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GenerateRampTex : MonoBehaviour
{
    [Header("水表面的颜色过渡")]
    public Gradient WaterGradient01;
    public Gradient WaterGradient02;
    public Texture2D RampTexture;

    //OnValidate方法，当数值有变动时会更新结果
    void OnValidate()
    {
        //创建一张纹理图
        RampTexture = new Texture2D(512, 2);
        //修改贴图的循环模式
        RampTexture.wrapMode = TextureWrapMode.Clamp;
        //修改贴图的过滤方式
        RampTexture.filterMode = FilterMode.Bilinear;
        int count = RampTexture.width * RampTexture.height;
        //为纹理图声明相对应数量的颜色数组
        Color[] cols = new Color[count];
        for (int i = 0; i < 511; i++)
        {
            cols[i] = WaterGradient01.Evaluate((float)i / 511);
        }
        for (int i = 512; i < 1023; i++)
        {
            cols[i] = WaterGradient01.Evaluate((float)(i - 512) / 511);
        }
        //把颜色应用到纹理上
        RampTexture.SetPixels(cols);
        RampTexture.Apply();

        //全局赋值,会将所有shader命名为_RampTexture的贴图全部赋值
        Shader.SetGlobalTexture("_RampTexture", RampTexture);
    }
}
