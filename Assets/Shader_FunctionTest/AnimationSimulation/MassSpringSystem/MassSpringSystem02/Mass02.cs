using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Mass02 : MonoBehaviour
{
    public float m = 1.0f;
    public Vector3 F;
    public Vector3 v;
    public bool isStaticPos = false;
    public Vector3 lastPostition;

    private void Start()
    {
        v = F = Vector3.zero;
        lastPostition = Vector3.zero;
    }
}
