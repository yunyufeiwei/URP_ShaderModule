using UnityEditor;
using UnityEngine;

public class CustomShaderGUI_02 : ShaderGUI
{
    MaterialEditor editor;
    MaterialProperty[] properties;
    private Material target;
    
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        this.editor = materialEditor;
        this.properties = properties;
        this.target = this.editor.target as Material;
        DoMain();
        GUILayout.Space(10);
        DoSecondary();
    }
    

    void DoMain()
    {
        //定义分组的名称，以及名称的风格样式，这里boldLabel表示了加粗
        GUILayout.Label("Main Map", EditorStyles.boldLabel);   
        
        // MaterialProperty mainTex = FindProperty("_MainTex", properties);
        MaterialProperty mainTex = FindPropertyOverride("_MainTex");
        // MaterialProperty tint = FindProperty("_Tint", properties);
        // MaterialProperty tint = FindPropertyOverride("_Tint");
        
        // GUIContent albedoLabel = new GUIContent("Albedo");
        //由于已经在着色器中命名了 main 纹理。我们可以使用该名称，我们可以通过属性访问该名称。这里的mainTex.displayName就是在shader中声明在面版上的显示名称,第二个参数可以不加，如果加了字符串，就能显示鼠标在放在该属性上的说明
        // GUIContent albedoLabel = new GUIContent(mainTex.displayName , "Abledo Map");
        //TexturePropertySingleLine方法需要显示两个参数，第一个是显示在面板上的重定义名称，第二个是shader传过来的Material Property类型的属性名
        
        // editor.TexturePropertySingleLine(albedoLabel, mainTex , FindPropertyOverride("_Tint"));
        editor.TexturePropertySingleLine(MakeLabel(mainTex.displayName , "Abledo Map"), mainTex , FindPropertyOverride("_Tint"));
        DoMetallic();
        DoSmoothness();
        DoNormals();
        editor.TextureScaleOffsetProperty(mainTex);
    }

    void DoMetallic()
    {
        MaterialProperty metallicMap = FindPropertyOverride("_MetallicMap");
        MaterialProperty metallic = FindPropertyOverride("_Metallic");
        editor.TexturePropertySingleLine(MakeLabel(metallicMap.displayName, "Metallic Map(R)"), metallicMap , metallicMap.textureValue ? null : metallic);
        //给后面面的属性添加缩进，需要注意的是，添加了需要缩进的属性后，在该属性的后面需要在添加一个减少缩进的代码，否则会让该属性后面的所有面板上的属性都缩进
        //EditorGUI.indentLevel += 2;
        // editor.ShaderProperty(metallic , MakeLabel(metallic.displayName , "Metallic Value"));
        //EditorGUI.indentLevel -= 2;
        //SetKeyword("_METALLIC_MAP" , metallicMap.textureValue);
    }

    void DoSmoothness()
    {
        MaterialProperty smooth = FindPropertyOverride("_Smoothness");
        EditorGUI.indentLevel += 2;
        editor.ShaderProperty(smooth , MakeLabel(smooth.displayName , "Smooth Value"));
        EditorGUI.indentLevel -= 2;
    }
    
    void DoNormals () 
    {
        MaterialProperty normalMap = FindPropertyOverride("_NormalMap");
        //第一个参数是使用C#显示在面板上的属性，第二个参数是从shader里面传递过来的属性变量
        // editor.TexturePropertySingleLine(MakeLabel(normalMap.displayName, "normalMap"), normalMap , FindPropertyOverride("_BumpScale"));
        //修改之后，如果没有添加发现贴图，那么就不会显示BumpScale的参数
        editor.TexturePropertySingleLine(MakeLabel(normalMap.displayName, "normalMap"), normalMap , normalMap.textureValue ? FindPropertyOverride("_BumpScale") : null);
    }

    void DoSecondary()
    {
        GUILayout.Label("Secondary Map", EditorStyles.boldLabel);
        MaterialProperty detailTex = FindPropertyOverride("_DetailTex");
        editor.TexturePropertySingleLine(MakeLabel(detailTex.displayName, "Albedo Multiplied by 2"),detailTex);
        DoSecondaryNormals();
        editor.TextureScaleOffsetProperty(detailTex);
    }

    void DoSecondaryNormals()
    {
        MaterialProperty detailNormalMap = FindPropertyOverride("_DetailNormalMap");
        editor.TexturePropertySingleLine(MakeLabel(detailNormalMap.displayName,"Second DetailNormal Map"), detailNormalMap ,detailNormalMap.textureValue? FindPropertyOverride("_BumpScale"):null);
    }

    //普通材质属性变量声明MaterialProperty mainTex = FindProperty("_MainTex", properties);，每次都需要在里面加一个property，使用该函数后，之需要在里面传递一个字符串就可以取到shader里面的属性
    MaterialProperty FindPropertyOverride (string name) 
    {
        return FindProperty(name, properties);
    }
    
    static GUIContent staticLabel = new GUIContent();
	
    static GUIContent MakeLabel (string text, string tooltip = null) 
    {
        staticLabel.text = text;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }

    void SetKeyword(string keyword, bool state)
    {
        if (state)
        {
            target.EnableKeyword(keyword);
        }
        else
        {
            target.DisableKeyword(keyword);
        }
    }
}
