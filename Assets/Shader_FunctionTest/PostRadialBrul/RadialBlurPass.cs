using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class RadialBlurPass : ScriptableRenderPass
{
    private static readonly string PassName = "RadialBlur";
    private static readonly int MainTexID = Shader.PropertyToID("_MainTex");
    private static readonly int TempTexID = Shader.PropertyToID("_RadialBlurTempTex");

    private Material m_Material;
    private RadialBlurVolume m_Volume;

    public RadialBlurPass(RenderPassEvent evt, Material mat)
    {
        renderPassEvent = evt;
        m_Material = mat;
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (m_Material == null)
        {
            Debug.LogWarning("[RadialBlur] Material 丢失");
            return;
        }

        // 从Volume栈获取参数
        var stack = VolumeManager.instance.stack;
        m_Volume = stack.GetComponent<RadialBlurVolume>();

        if (m_Volume == null || !m_Volume.IsActive())
            return;

        // 忽略Scene视图相机（可选）
        if (renderingData.cameraData.cameraType == CameraType.Preview)
            return;

        CommandBuffer cmd = CommandBufferPool.Get(PassName);
        DoRadialBlur(cmd, renderingData);
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }

    private void DoRadialBlur(CommandBuffer cmd, RenderingData renderingData)
    {
        // 获取当前相机颜色RT（此时已包含半透明物体）
        RTHandle source = renderingData.cameraData.renderer.cameraColorTargetHandle;

        RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
        desc.depthBufferBits = 0;

        // 设置Shader参数
        m_Material.SetFloat("_BlurStrength", m_Volume.blurStrength.value);
        //m_Material.SetFloat("_CenterX", m_Volume.centerX.value);
        //m_Material.SetFloat("_CenterY", m_Volume.centerY.value);
        m_Material.SetInt("_Iterations", m_Volume.iterations.value);

        // 申请临时RT -> Blit到临时RT（应用模糊）-> 写回源RT
        cmd.GetTemporaryRT(TempTexID, desc.width, desc.height, 0, FilterMode.Bilinear, RenderTextureFormat.Default);
        cmd.SetGlobalTexture(MainTexID, source);
        cmd.Blit(source, TempTexID, m_Material);
        cmd.Blit(TempTexID, source);
        cmd.ReleaseTemporaryRT(TempTexID);
    }
}
