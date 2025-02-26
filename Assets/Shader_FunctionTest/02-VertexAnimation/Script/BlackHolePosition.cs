using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BlackHolePosition : MonoBehaviour
{
    public Transform targetObj;
    public Material blockMat;

    void Update()
    {
        blockMat.SetVector("_BlackHolePos" , targetObj.position);        //将公开在外部的player位置信息传递到shader中
    }
}
