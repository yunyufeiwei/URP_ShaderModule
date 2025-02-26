using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class WaterRippleRenderPass : ScriptableRenderPass
{
    static readonly string tag = "WaterRippleRender";
    static readonly int sourceTexID = Shader.PropertyToID("_MainTex");
    static readonly int destinationTexID = Shader.PropertyToID("destinationName");
    
    private Material _material;
    private WaterRippleRenderVolume _volume;
    
    private RTHandle source { get; set; }
    
    private float waveStartTime;
    
    public WaterRippleRenderPass(RenderPassEvent ent , Shader shader)
    {
        renderPassEvent = ent;
        if(shader == null){return;}
        _material = CoreUtils.CreateEngineMaterial(shader);
    }
    
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (_material == null)
        {
            Debug.LogWarning("材质初始化创建失败！");
            return;
        }
        var stack = VolumeManager.instance.stack;
        _volume = stack.GetComponent<WaterRippleRenderVolume>();
        if (_volume.KeyWord == false)
        {
            // Debug.LogError("Volume Component is Not Use!");
            return;
        }
        CommandBuffer cmd = CommandBufferPool.Get(tag);
        
        OnRenderImage(cmd , renderingData);
        
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }

    void OnRenderImage(CommandBuffer cmd , RenderingData renderingData)
    {
        source = renderingData.cameraData.renderer.cameraColorTargetHandle;

        RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;
        int rtWidth = descriptor.width;
        int rtHeight = descriptor.height;
        
        cmd.SetGlobalTexture(sourceTexID , source);
        cmd.GetTemporaryRT(destinationTexID , rtWidth , rtHeight , 0 , FilterMode.Bilinear , format:RenderTextureFormat.Default);

        _material.SetVector("_StartPos" , _volume._startPos.value);
        _material.SetFloat("_waveLength" , _volume._waveLength.value);
        _material.SetFloat("_waveHeight" , _volume._waveHeight.value);
        _material.SetFloat("_waveWidth" , _volume._waveWidth.value);
        _material.SetFloat("_currentWaveDis" , _volume._currentWaveDis.value);
        
        cmd.Blit(source , destinationTexID , _material);
        cmd.Blit(destinationTexID , source);
        
        cmd.ReleaseTemporaryRT(destinationTexID);
    }
}


