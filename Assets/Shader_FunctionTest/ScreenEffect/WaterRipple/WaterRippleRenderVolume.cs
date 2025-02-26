using System;
using UnityEngine;
using UnityEngine.Rendering;

[Serializable,VolumeComponentMenu("CustomPostProcessing/WaterRippleRender")]
public class WaterRippleRenderVolume : VolumeComponent
{
    public BoolParameter KeyWord = new BoolParameter(false, BoolParameter.DisplayType.Checkbox);
    public Vector4Parameter _startPos = new Vector4Parameter(Vector4.zero);
    public FloatParameter _waveLength = new FloatParameter(92.5f);
    public FloatParameter _waveHeight = new FloatParameter(0.28f);
    public FloatParameter _waveWidth = new FloatParameter(0.951f);
    public FloatParameter _currentWaveDis = new FloatParameter(0.187f);
}
