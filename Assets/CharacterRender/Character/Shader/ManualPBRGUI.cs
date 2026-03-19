using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.Rendering;
using UnityEngine;

public class ManualPBRGUI : ShaderGUI
{
    private MaterialProperty _baseColor;
    private MaterialProperty _albedo;
    private MaterialProperty _maskMap;
    private MaterialProperty _roughness;
    private MaterialProperty _normalMap;
    private MaterialProperty _normalScale;
    private MaterialProperty _emissiveMap;
    private MaterialProperty _emissiveColor;
    private MaterialProperty _emissiveIntensity;
    
    override public void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        _baseColor = FindProperty("_BaseColor", properties);
        _albedo = FindProperty("_BaseMap", properties);
        _maskMap = FindProperty("_MaskMap", properties);
        _roughness = FindProperty("_Roughness", properties);
        _normalMap = FindProperty("_NormalMap", properties);
        _normalScale = FindProperty("_NormalScale", properties);
        _emissiveMap = FindProperty("_EmissiveMap", properties);
        _emissiveColor = FindProperty("_EmissiveColor", properties);
        _emissiveIntensity = FindProperty("_EmissiveIntensity", properties);

        Draw(materialEditor, properties);
    }

    private void Draw(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        EditorGUILayout.LabelField("BaseProperty",EditorStyles.boldLabel);
        EditorGUILayout.BeginVertical(GUI.skin.box);
        {
            materialEditor.TexturePropertySingleLine(new GUIContent("Albedo","Lit(RGB) + Alpha(A)"), _albedo, _baseColor);
            materialEditor.TexturePropertySingleLine(new GUIContent("Mask", "R-Metallic , G-Roughness, B-Ao"), _maskMap);
            materialEditor.TexturePropertySingleLine(new GUIContent("Normal", "Here we input the normal map in tangent space"), _normalMap, _normalScale);
            materialEditor.RangeProperty(_roughness, "Roughness");
        }
        EditorGUILayout.EndVertical();
        EditorGUILayout.Space(20);
        
        EditorGUILayout.LabelField("EmissiveProperty",EditorStyles.boldLabel);
        EditorGUILayout.BeginVertical(GUI.skin.box);
        {
            materialEditor.TexturePropertySingleLine(new GUIContent("EmissiveTexture", "Here we input the mask image of the self luminous texture"),_emissiveMap, _emissiveColor);
            materialEditor.RangeProperty(_emissiveIntensity, "Intensity");
        }
        EditorGUILayout.EndVertical();
        EditorGUILayout.Space(20);
        
        EditorGUILayout.LabelField("Advanced Options",EditorStyles.boldLabel);
        EditorGUILayout.BeginVertical(GUI.skin.box);
        {
            materialEditor.RenderQueueField();
            materialEditor.EnableInstancingField();
            materialEditor.DoubleSidedGIField();
        }
        EditorGUILayout.EndVertical();
    }
}
