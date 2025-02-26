using System;
using System.Collections.Generic;
using UnityEngine;

public class TransformationGrid : MonoBehaviour
{
    public Transform prefab;
    public int gridResolution = 10;

    private Transform[] grid;
    private List<Transformation> transformations;

    private Matrix4x4 transformation;

    private void Awake()
    {
        grid = new Transform[gridResolution * gridResolution * gridResolution];
        for (int i = 0, z = 0; z < gridResolution; z++) 
        {
            //grid[i] = CreateGridPoint(1, 1, z);
            for (int y = 0; y < gridResolution; y++) 
            {
                //grid[i] = CreateGridPoint(1, y, z);
                for (int x = 0; x < gridResolution; x++, i++) 
                {
                    grid[i] = CreateGridPoint(x, y, z);
                }
            }
        }
        transformations = new List<Transformation>();
    }

    void Update()
    {
        //可以在脚本的point坐标移动时，每帧更新移动效果
        //GetComponents<Transformation>(transformations);     
        updateTransformations();
        for (int i = 0, z = 0; z < gridResolution; z++) 
        {
            for (int y = 0; y < gridResolution; y++) 
            {
                for (int x = 0; x < gridResolution; x++, i++) 
                {
                    grid[i].localPosition = TransformPoint(x, y, z);
                }
            }
        }
    }

    void updateTransformations()
    {
        GetComponents<Transformation>(transformations);
        if (transformations.Count > 0)
        {
            transformation = transformations[0].Matrix;
            for (int i = 1; i < transformations.Count; i++)
            {
                transformation = transformations[i].Matrix * transformation; 
            }
        }
    }
    
    Vector3 TransformPoint (int x, int y, int z) 
    {
        Vector3 coordinates = GetCoordinates(x, y, z);
        // for (int i = 0; i < transformations.Count; i++) 
        // {
        //     coordinates = transformations[i].Apply(coordinates);
        // }
        // return coordinates;

        //矩阵写法
        return transformation.MultiplyPoint(coordinates);
    }
    
    Transform CreateGridPoint (int x, int y, int z) 
    {
        Transform point = Instantiate<Transform>(prefab);
        point.parent = transform;
        point.localPosition = GetCoordinates(x, y, z);
        point.GetComponent<MeshRenderer>().material.color = new Color((float)x / gridResolution,
                                                                      (float)y / gridResolution,
                                                                      (float)z / gridResolution);
        return point;
    }
    
    Vector3 GetCoordinates (int x, int y, int z) 
    {
        return new Vector3( x - (gridResolution - 1) * 0.5f,
                            y - (gridResolution - 1) * 0.5f,
                            z - (gridResolution - 1) * 0.5f);
    }
}
