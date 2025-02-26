using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Mass01 : MonoBehaviour
{
    public float m = 0.1f;
    public Vector3 F;
    public Vector3 v;

    public bool isStaticPos = false;
    public float drag = 1;  //阻力
        
    void Start()
    {
        v = F = Vector3.zero;
    }

    public void Simulate(float dt)
    {
        if (isStaticPos)
        {
            F = Vector3.zero;
            return;
        }
        
        // 防止异常
        if (double.IsNaN(v.x) || double.IsNaN(F.x))
        {
            v = F = Vector3.zero;
        }
        
        //重力 f = mg
        F += m * 9.78f * Vector3.down.normalized;
        F += -v.normalized * drag * Mathf.Pow(v.magnitude, 2);

        Vector3 a = F / m;
        v += dt * a;
        
        //碰撞检测
        RaycastHit hit;
        if (Physics.SphereCast(transform.position, 0.005f, v.normalized, out hit, dt * v.magnitude * 1.5f))
        {
            v = Vector3.Reflect(v.normalized, hit.normal) * v.magnitude * 0.5f * Mathf.Clamp01(hit.distance * 300);
            if (v.magnitude < 0.01f)
            {
                v = Vector3.zero;
            }
        }

        Vector3 s = dt * v;
        transform.position += s;
        F = Vector3.zero;
    }
    
}
