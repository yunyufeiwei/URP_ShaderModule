using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Dissolve : MonoBehaviour
{
    void Start()
    {
        Material mat = GetComponent<MeshRenderer>().material;
        mat.SetFloat("_MaxDistance" , CalculateMaxDistance());
    }

    //计算顶点到开始消融点的最大距离
    float CalculateMaxDistance()
    {
        float maxDistance = 0.0f;
        Vector3[] vertices = GetComponent<MeshFilter>().mesh.vertices;  //获取模型的网格组件

        //遍历模型网格上的顶点
        for(int i = 0; i<vertices.Length;i++)
        {
            Vector3 v1 = vertices[i];
            for(int k = 0; k < vertices.Length; k++)
            {
                if(i==k) continue;

                Vector3 v2 = vertices[k];
                float mag = (v1- v2).magnitude;
                if(maxDistance < mag) maxDistance = mag;
            }
        }
        return maxDistance;
    }
    
}
