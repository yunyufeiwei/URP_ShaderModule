using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

/// <summary>
/// 在半透明渲染完成后，将相机颜色RT（包含不透明+半透明）拷贝到一张全局纹理
/// 供场景中的半透明面片Shader采样使用
/// </summary>
public class GrabTransparentPass : ScriptableRenderPass
{
    private static readonly string PassName = "GrabTransparentColor";
    private static readonly int GrabTexID = Shader.PropertyToID("_GrabTransparentTex");

    private RenderTargetIdentifier m_GrabTarget;

    public GrabTransparentPass(RenderPassEvent evt)
    {
        renderPassEvent = evt;
    }

    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
        desc.depthBufferBits = 0;
        // 申请一张与相机同尺寸的临时RT
        cmd.GetTemporaryRT(GrabTexID, desc, FilterMode.Bilinear);
        m_GrabTarget = new RenderTargetIdentifier(GrabTexID);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        CommandBuffer cmd = CommandBufferPool.Get(PassName);

        // 将当前相机颜色RT拷贝到全局纹理（此时已包含不透明+半透明物体）
        RTHandle source = renderingData.cameraData.renderer.cameraColorTargetHandle;
        cmd.Blit(source, m_GrabTarget);

        // 设置为全局纹理，任何Shader都可以通过 _GrabTransparentTex 采样
        cmd.SetGlobalTexture(GrabTexID, m_GrabTarget);

        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }

    public override void OnCameraCleanup(CommandBuffer cmd)
    {
        cmd.ReleaseTemporaryRT(GrabTexID);
    }
}
