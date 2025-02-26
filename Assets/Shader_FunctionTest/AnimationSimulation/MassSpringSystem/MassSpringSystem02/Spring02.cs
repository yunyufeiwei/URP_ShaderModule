using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Spring02 : MonoBehaviour
{
    // 质点A
    public Mass02 mass_a;
    // 质点B
    public Mass02 mass_b;
    /// 弹力系数
    public float ks = 35000;
    // 阻力系数
    public float kd = 150f;
    // 变形长度
    public float restLen = 1f;
}
