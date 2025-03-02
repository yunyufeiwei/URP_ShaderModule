//Blit参考 https://github.com/Unity-Technologies/UniversalRenderingExamples 的 DrawFullscreenFeature、DrawFullscreenPass和编辑器代码DrawFullScreenFeatureDrawer
//更多参考Unity自带的RenderObjects.cs

using UnityEngine;
using UnityEngine.Rendering.Universal;

public class EdgeDetectionColorPPFeature : ScriptableRendererFeature
{
    [SerializeField]
    private EdgePPPass.Settings _edgeSettings = new EdgePPPass.Settings();
    [SerializeField]
    private Color _edgeColor = Color.black;
    [SerializeField]
    private float _sampleDistance = 1;
    [SerializeField]
    private float _edgeExponent = 50;

    private EdgePPPass _blitPass;

    //将shader里面的参数属性传递到C#脚本
    private int _edgeColorPropId = Shader.PropertyToID("_EdgeColor");
    private int _sampleDistancePropId = Shader.PropertyToID("_SampleDistance");
    private int _edgeExponentPropId = Shader.PropertyToID("_EdgeExponent");

    public Color edgeColor { get { return _edgeColor; } set { _edgeColor = value; } }
    public float sampleDistance { get { return _sampleDistance; } set { _sampleDistance = value; } }
    public float edgeExponent { get { return _edgeExponent; } set { _edgeExponent = value; } }
    public override void Create()
    {
        _blitPass = new EdgePPPass("PostProcessing Edge Detection Color", _edgeSettings);
    }

    //将shader传递的参数和在RenderFeature申明的参数进行关联
    private void UpdateData(Color edgeColor, float sampleDistance,float edgeExponent)
    {
        _edgeSettings.blitMaterial.SetColor(_edgeColorPropId, edgeColor);
        _edgeSettings.blitMaterial.SetFloat(_sampleDistancePropId, sampleDistance);
        _edgeSettings.blitMaterial.SetFloat(_edgeExponentPropId, edgeExponent);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (_edgeSettings.blitMaterial == null)
        {
            Debug.LogWarningFormat("Missing Blit Material. {0} blit pass will not execute. Check for missing reference in the assigned renderer.", GetType().Name);
            return;
        }
        UpdateData(edgeColor, sampleDistance, edgeExponent);
        renderer.EnqueuePass(_blitPass);
    }
}

