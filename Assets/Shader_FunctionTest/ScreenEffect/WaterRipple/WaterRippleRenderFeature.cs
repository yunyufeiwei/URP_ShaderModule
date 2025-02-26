using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class WaterRippleRenderFeature : ScriptableRendererFeature
{
    public Shader shader;
    public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;

    private WaterRippleRenderPass m_ScriptablePass;

    public override void Create()
    {
        this.name = "WaterRipple";
        m_ScriptablePass = new WaterRippleRenderPass(renderPassEvent , shader);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


