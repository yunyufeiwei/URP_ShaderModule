using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ZoomRenderPass : ScriptableRenderPass
{
    private static readonly string tag = "ZoomRenderPass";
    private static readonly int sourceTexID = Shader.PropertyToID("_MainTex");
    private static readonly int destinationTexID = Shader.PropertyToID("_destinationTexture");
    
    //创建一个纹理对象
    private RTHandle _source;
    private RTHandle _destination;
    
    private readonly Material _zoomMaterial;
    private ZoomVolume _volume;

    // public Vector2 _pos;
    // public float _zoomFactor; //分辨率比例
    // public float _size;
    // public float _edgeFactor;

    public ZoomRenderPass(RenderPassEvent ent , Shader m_shader)
    {
        renderPassEvent = ent;
        var shader = m_shader;

        _zoomMaterial = CoreUtils.CreateEngineMaterial(shader);
    }
        
    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        //获取当前相机的颜色缓存，赋值给声明的RTHanld
        _source = renderingData.cameraData.renderer.cameraColorTargetHandle;
        
        //此结构体包含创建RenderTexture所需的所有信息(包括宽度、高度、抗锯齿采样、mipmap级别、纹理格式等等)。它可以被复制、缓存和重用，以轻松创建共享相同属性的RenderTextures。
        RenderTextureDescriptor textureDescriptor = renderingData.cameraData.cameraTargetDescriptor;
        textureDescriptor.depthBufferBits = 0;
        int rtWidth = textureDescriptor.width;
        int rtHeight = textureDescriptor.height;
        
        //添加或获取临时渲染纹理
        cmd.GetTemporaryRT(destinationTexID , rtWidth , rtHeight ,depthBuffer:0 , FilterMode.Bilinear , format:RenderTextureFormat.Default);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (!_zoomMaterial)
        {
            Debug.LogWarning("Material is Missing!");
            return;
        }

        CommandBuffer cmd = CommandBufferPool.Get(tag);

        using (new ProfilingScope(cmd,new ProfilingSampler("Zoom")))
        {
             context.ExecuteCommandBuffer(cmd);
             var stack = VolumeManager.instance.stack;
             _volume = stack.GetComponent<ZoomVolume>();
            
             cmd.SetGlobalTexture(sourceTexID , _source);

            //基于材质球的属性类型，将Pass中的值传递到shader属性中
             _zoomMaterial.SetVector ("_Pos", _volume.pos.value);
             _zoomMaterial.SetFloat ("_ZoomFactor", _volume.zoomFactor.value);
             _zoomMaterial.SetFloat ("_EdgeFactor", _volume.edgeFactor.value);
             _zoomMaterial.SetFloat ("_Size", _volume.size.value);
             
             cmd.Blit(_source, destinationTexID, _zoomMaterial);
             cmd.Blit(destinationTexID , _source);
        }
        
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }

    public override void OnCameraCleanup(CommandBuffer cmd)
    {
        //释放申请的临时纹理
        cmd.ReleaseTemporaryRT(destinationTexID);
    }
}
