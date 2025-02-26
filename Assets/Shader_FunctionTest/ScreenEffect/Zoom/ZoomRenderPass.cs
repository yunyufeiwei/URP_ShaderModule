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
    
    //����һ���������
    private RTHandle _source;
    private RTHandle _destination;
    
    private readonly Material _zoomMaterial;
    private ZoomVolume _volume;

    // public Vector2 _pos;
    // public float _zoomFactor; //�ֱ��ʱ���
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
        //��ȡ��ǰ�������ɫ���棬��ֵ��������RTHanld
        _source = renderingData.cameraData.renderer.cameraColorTargetHandle;
        
        //�˽ṹ���������RenderTexture�����������Ϣ(������ȡ��߶ȡ�����ݲ�����mipmap���������ʽ�ȵ�)�������Ա����ơ���������ã������ɴ���������ͬ���Ե�RenderTextures��
        RenderTextureDescriptor textureDescriptor = renderingData.cameraData.cameraTargetDescriptor;
        textureDescriptor.depthBufferBits = 0;
        int rtWidth = textureDescriptor.width;
        int rtHeight = textureDescriptor.height;
        
        //��ӻ��ȡ��ʱ��Ⱦ����
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

            //���ڲ�������������ͣ���Pass�е�ֵ���ݵ�shader������
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
        //�ͷ��������ʱ����
        cmd.ReleaseTemporaryRT(destinationTexID);
    }
}
