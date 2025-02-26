using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DissolveEnvironment : MonoBehaviour
{
    public Vector3 dissovleStartPoint;
    [Range(0,1)]
    public float dissolveThreshold = 0.0f;
    [Range(0,1)]
    public float distanceEffect = 0.6f;

    void Start()
    {
        //获取所有GameObject上的模型，模型组件类型是meshFilters
        MeshFilter[] meshFilters = GetComponentsInChildren<MeshFilter>();
        float maxDistance = 0.0f;

        for(int i = 0;i < meshFilters.Length;i++)
        {
            float distance = CalculateMaxDistance(meshFilters[i].mesh.vertices);
            if(distance > maxDistance)
            {
                maxDistance = distance;
            }
        }

        //获取挂载脚本下面的所有该物体的MeshRenderer组件中的material，将C#脚本上定义的属性参数传递到Shader
        MeshRenderer[] meshRenderers = GetComponentsInChildren<MeshRenderer>();
        for(int i = 0;i < meshRenderers.Length;i++)
        {
            meshRenderers[i].material.SetVector("_StartPoint" , dissovleStartPoint);
            meshRenderers[i].material.SetFloat("_MaxDistance",maxDistance);
        }
    }

    void Update()
    {
        MeshRenderer[] meshRenderers = GetComponentsInChildren<MeshRenderer>();
        for (int i = 0; i < meshRenderers.Length; i++)
        {
            meshRenderers[i].material.SetFloat("_Threshold", dissolveThreshold);
            meshRenderers[i].material.SetFloat("_DistanceEffect", distanceEffect);
        }
    }

    //计算给定顶点集合到消融开始点的最大距离
    float CalculateMaxDistance(Vector3[] vertices)
    {
        float maxDistance = 0;
        for(int i = 0; i < vertices.Length ; i++)
        {
            Vector3 vert = vertices[i];
            float distance = (vert - dissovleStartPoint).magnitude; //使用magnitude计算模长，求出每一个点到消融开始点的距离
            if(distance > maxDistance)
            {
                maxDistance = distance;     //如果计算出来的距离大于设置的最大距离，那么将该距离设置为最大距离
            }
        }
        return maxDistance;
    }
}
