using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SendPlayerPos : MonoBehaviour
{
    public Transform player;
    public Material blockMat;

    void Update()
    {
        blockMat.SetVector("_PlayerPos" , player.position);        //将公开在外部的player位置信息传递到shader中
    }
}
