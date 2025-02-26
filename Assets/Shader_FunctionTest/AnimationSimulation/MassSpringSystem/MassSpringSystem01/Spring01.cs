using UnityEngine;

public class Spring01 : MonoBehaviour
{
    //质点A
    public Mass01 mass_a;
    //质点B
    public Mass01 mass_b;
    //弹力系数
    public float ks = 100;
    //阻力系数
    public float kd = 1.0f;
    //弹簧长度
    public float restLen = 0.3f;

    public void Simulate()
    {
        // 弹簧的物理模型用胡克定律来描述，质点受到两个力的作用，分别是弹力和阻力
        //胡克定律  弹力 f = 弹力系数（ks） * 变形长度
        Vector3 pos_ab = mass_b.transform.position - mass_a.transform.position;
        Vector3 f_ab = ks * pos_ab.normalized * (pos_ab.magnitude - restLen);

        // 阻力
        Vector3 v_ab = mass_a.v - mass_b.v;
        Vector3 d_ab = -kd * pos_ab.normalized * Vector3.Dot(v_ab, pos_ab.normalized);

        // 质点受到的 合力 = 弹力 + 阻力
        mass_a.F += f_ab;
        mass_a.F += d_ab;

        mass_b.F += -f_ab;
        mass_b.F += -d_ab;
    }
}
