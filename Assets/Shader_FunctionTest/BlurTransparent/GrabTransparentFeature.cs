using System;
using UnityEngine;
using UnityEngine.Rendering.Universal;

/// <summary>
/// Renderer Feature：在半透明渲染后拷贝包含半透明的屏幕纹理
/// 添加到 URP Renderer Data 上即可使用
/// </summary>
public class GrabTransparentFeature : ScriptableRendererFeature
{
    [Serializable]
    public class Settings
    {
        [Tooltip("拷贝时机，默认在半透明渲染之后")]
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    [SerializeField] public Settings settings = new Settings();
    private GrabTransparentPass m_Pass;

    public override void Create()
    {
        name = "GrabTransparentColor";
        m_Pass = new GrabTransparentPass(settings.renderPassEvent);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_Pass);
    }
}
