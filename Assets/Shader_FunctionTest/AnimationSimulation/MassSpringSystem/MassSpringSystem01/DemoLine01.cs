using System;
using System.Collections.Generic;
using UnityEngine;

public class DemoLine01 : MonoBehaviour
{
    public float simulateStep = 0.01f;
    public int massCount = 5;   //声明质点数量
    private List<Spring01> allSprings;
    private Mass01[] allMass;

    private void Start()
    {
        allMass = new Mass01[massCount];
        
        float disStep = 0.3f;
        float massSize = 0.1f;
        
        //创建质点
        for (int i = 0; i < massCount; i++)
        {
            var item = GameObject.CreatePrimitive(PrimitiveType.Sphere).AddComponent<Mass01>();       //生成图元
            item.transform.SetParent(transform);                        //设置生成图元的父类组件，这里就是直接设置在了挂载当前脚本的Gameobject上
            item.transform.localScale = Vector3.one * massSize;         //设置生成质点的缩放值
            Destroy(item.GetComponent<Collider>());                 //销毁这个每一个生成质点Gameobject物体上的Collider组件
            item.transform.localPosition = Vector3.left * disStep * i;       //设置生成质点的位置，每一个的位置为上一个位置加上disStep距离
            allMass[i] = item;
        }
        
        //创建弹簧
        allSprings = new List<Spring01>();
        for (int i = 0; i < massCount - 1; i++)
        {
            var sp = allMass[i].gameObject.AddComponent<Spring01>();
            sp.mass_a = sp.GetComponent<Mass01>();
            sp.mass_b = allMass[i + 1].GetComponent<Mass01>();
            allSprings.Add(sp);
        }

        allMass[0].isStaticPos = true;//设置第一个质点为起始点
    }

    void Update()
    {
        var dt = simulateStep;
        for (int i = 0 , len = allSprings.Count; i < len; i++)
        {
            //产生所有弹簧力
            allSprings[i].Simulate();
        }

        for (int i = 0; i < massCount; i++)
        {
            //计算这一帧所有合力 质点运动变化
            allMass[i].Simulate(dt);
        }
    }
}
