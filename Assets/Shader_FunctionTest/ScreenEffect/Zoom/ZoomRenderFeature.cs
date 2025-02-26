using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ZoomRenderFeature : ScriptableRendererFeature
{
    // [Range(-2.0f, 2.0f)] public float zoomFactor = 0.4f;     //�Ŵ�ǿ��
    // [Range(0.0f, 0.2f)] public float size = 0.15f;            //�Ŵ󾵴�С
    // [Range(0.0001f, 0.1f)] public float edgeFactor = 0.05f;     //͹����Եǿ��
    // public Vector2 pos = new Vector2(0.5f, 0.5f);       //͹�����ĵ�λ��
    
    //��ʾ��RenderFeature����ϵ�����
    [System.Serializable]
    public class ZoomSettings
    {
        public Shader shader;
        public RenderPassEvent eventPass = RenderPassEvent.AfterRenderingPostProcessing;
    }
    
    //��Ⱦ����
    public ZoomSettings setting = new ZoomSettings();
    private ZoomRenderPass m_ScriptablePass;

    public override void Create()
    {
        this.name = "ZoomRenderFeature";
        m_ScriptablePass = new ZoomRenderPass(setting.eventPass , setting.shader);
        
        //��RenderFeature�е����Դ��ݵ�RenderPass��
        // m_ScriptablePass._pos = pos;
        // m_ScriptablePass._zoomFactor = zoomFactor;
        // m_ScriptablePass._size = size;
        // m_ScriptablePass._edgeFactor = edgeFactor;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


