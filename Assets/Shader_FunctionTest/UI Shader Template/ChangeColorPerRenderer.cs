using UnityEngine;

public class ChangeColorPerRenderer : MonoBehaviour
{
    
    public Color newColor = Color.green;
    private Renderer _renderer;
    private MaterialPropertyBlock _propBlock;
    

    void Start()
    {
        _propBlock = new MaterialPropertyBlock();
        _renderer = GetComponent<Renderer>();
    }

    void Update()
    {
        Color crrrentColor = _propBlock.GetColor("_GlobalColor");
            
        float lerpedValue = Mathf.Lerp(0.0f, 1.0f, Mathf.PingPong(Time.time * 0.05f, 1.0f));
        // 使用 MaterialPropertyBlock 修改颜色（不影响其他使用相同材质的对象）
        _renderer.GetPropertyBlock(_propBlock);
        _propBlock.SetColor("_GlobalColor", Color.Lerp(crrrentColor , newColor , lerpedValue)); // "_Color" 是在 Shader 中定义的变量
        _renderer.SetPropertyBlock(_propBlock);
        
        // Shader.SetGlobalColor("_GlobalColor", Color.Lerp(Color.green,Color.red,Mathf.PingPong(Time.time*0.5f , 1.0f)));
        
    }
}