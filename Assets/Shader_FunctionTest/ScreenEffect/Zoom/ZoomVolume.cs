using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class ZoomVolume : VolumeComponent
{
    public Vector2Parameter pos = new Vector2Parameter(Vector2.zero);
    public ClampedFloatParameter zoomFactor = new ClampedFloatParameter(0.4f, -2.0f, 2.0f);
    public ClampedFloatParameter size = new ClampedFloatParameter(0.15f, 0.0f, 0.2f);
    public ClampedFloatParameter edgeFactor = new ClampedFloatParameter(0.05f, 0.0001f, 0.1f);

    //如何通过监测鼠标的事实位置，将放大镜的值传递给Pass
    void Update()
    {
        if (Input.GetMouseButton(0))
        {
            Vector2 mousePos = Input.mousePosition;
            Vector2 screenPos = new Vector2(mousePos.x / Screen.width, mousePos.y / Screen.height);
        }
    }
}


