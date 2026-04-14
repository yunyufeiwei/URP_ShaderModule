using System;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class RadialBlurFeature : ScriptableRendererFeature
{
    [Serializable]
    public class Settings
    {
        public Material material;
        // 关键：设置在半透明渲染之后执行，这样才能对半透明物体也产生模糊效果
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
    }

    [SerializeField] public Settings settings = new Settings();
    private RadialBlurPass m_Pass;

    public override void Create()
    {
        name = "RadialBlur";
        m_Pass = new RadialBlurPass(settings.renderPassEvent, settings.material);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (settings.material == null)
            return;
        renderer.EnqueuePass(m_Pass);
    }
}
