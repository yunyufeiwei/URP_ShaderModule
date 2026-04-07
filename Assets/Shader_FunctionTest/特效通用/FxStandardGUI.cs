using System.Collections;
using System;
using UnityEngine;
using UnityEditor;

public class FxStandardGUI : ShaderGUI
{
    #region MyRegion
    private enum BlendMode
    {
        Add,
        Transparent
    }

    private enum FaceMode
    {
        One,
        Two
    }

    private enum ZTestMode
    {
        On,
        Off
    }

    private enum MainTexRGBA
    {
        RGB,
        R,
        G,
        B,
        A
    }

    private enum MaskTexRGBA
    {
        A,
        R,
        G,
        B
        
    }

    private enum DistortionRGBA
    {
        R,
        G,
        B,
        A 
    }
    private enum DissolutionRGBA
    {
        R,
        G,
        B,
        A 
    }
    #endregion
    
    public static Texture2D WHXSJ_icon;

    MaterialProperty _BlendMode = null;
    MaterialProperty _FaceMode = null;
    MaterialProperty _ZTestMode = null;

    MaterialProperty _MainTexPopUp = null;
    MaterialProperty _MaskTexPopUp = null;
    MaterialProperty _DistortionPopUp = null;
    MaterialProperty _DissolutionPopUp = null;

    MaterialProperty _IsStreamerMode = null;
    
    MaterialProperty _AlphaValue = null;
    MaterialProperty _Color = null;
    MaterialProperty _MainTex = null;
    MaterialProperty _USpeed = null;
    MaterialProperty _VSpeed = null;
    MaterialProperty _LerpColor = null;
    MaterialProperty _LerpValue = null;
    MaterialProperty _DiffuseRotate = null;
    MaterialProperty _DiffuseAngle = null;
    
    //闪烁遮罩
    MaterialProperty _UseFlicker = null;
    MaterialProperty _FlickerFrequency = null;
    MaterialProperty _FlickerAmplitude = null;

    //基础遮罩
    MaterialProperty _DiffuseMask = null;
    MaterialProperty _DiffuseMaskLayerShown = null;
    MaterialProperty _DiffuseMaskTex = null;
    MaterialProperty _Mask_USpeed = null;
    MaterialProperty _Mask_VSpedd = null;
    MaterialProperty _MaskRotate = null;
    MaterialProperty _MaskAngle = null;
   
    //扭曲效果
    MaterialProperty _Distortion = null;
    MaterialProperty _DistortionLayerShown = null;
    MaterialProperty _DistortionTex = null;
    MaterialProperty _DistortionIntensity = null;
    MaterialProperty _Distortion_USpeed = null;
    MaterialProperty _Distortion_VSpeed = null;

    //溶解效果
    MaterialProperty _Dissolution = null;
    MaterialProperty _DissolutionLayerShown = null;
    MaterialProperty _DissolutionTex = null;
    MaterialProperty _Dissolvability = null;
    MaterialProperty _Eclosion = null;
    MaterialProperty _EdgeColor = null;
    MaterialProperty _EdgeWidth = null;
    MaterialProperty _Dissolution_USpeed = null;
    MaterialProperty _Dissolution_VSpeed = null;

    MaterialEditor m_MaterialEditor;
    // bool m_FirstTimeApply = true;

    private static class Styles
    {
        public static readonly string[] blendNames = Enum.GetNames(typeof(BlendMode));
        public static readonly string[] faceNames = Enum.GetNames(typeof(FaceMode));
        public static readonly string[] ztestNames = Enum.GetNames(typeof(ZTestMode));
        public static GUIContent BlendModeText = new GUIContent("混合模式");
        public static GUIContent FaceModeText = new GUIContent("单双面","双面渲染双倍消耗，尽量选择单面");
        public static GUIContent ZTestModeText = new GUIContent("深度检测");

        public static readonly string[] MainTexRGBAs = Enum.GetNames(typeof(MainTexRGBA));
        public static readonly string[] MaskTexRGBAs = Enum.GetNames(typeof(MaskTexRGBA));
        public static readonly string[] DistortionRGBAs = Enum.GetNames(typeof(DistortionRGBA));
        public static readonly string[] DissolutionRGBAs = Enum.GetNames(typeof(DissolutionRGBA));

        public static GUIContent AlphaValueText = new GUIContent("Alpha值");
        public static GUIContent ColorText = new GUIContent("基础颜色");
        public static GUIContent BaseTextureText = new GUIContent("基础贴图");
        public static GUIContent USpeedText = new GUIContent("USpeed");
        public static GUIContent VSpeedText = new GUIContent("VSpeed");
        public static GUIContent LerpColorText = new GUIContent("插值颜色");
        public static GUIContent LerpValueText = new GUIContent("插值阈值");
        public static GUIContent DiffuseRotateText = new GUIContent("贴图旋转","性能消耗较大，旋转角度为0时请取消勾选");
        public static GUIContent DiffuseAngleText = new GUIContent("旋转角度");
        
        public static GUIContent FlickerToggle = new GUIContent("启用闪烁");
        public static GUIContent FlickerFrequency = new GUIContent("闪烁频率");
        public static GUIContent FlickerAmplitude = new GUIContent("闪烁亮度");
        
        public static GUIContent IsStreamerMode = new GUIContent("主播模式");

        //基础遮罩贴图
        public static GUIContent DiffuseMaskText = new GUIContent("基础遮罩");
        public static GUIContent DiffuseMaskTextureText = new GUIContent("遮罩贴图","Mask(A)");
        public static GUIContent MaskUSpeedText = new GUIContent("Mask_USpeed");
        public static GUIContent MaskVSpeedText = new GUIContent("Mask_VSpeed");
        public static GUIContent MaskRotateText = new GUIContent("贴图旋转", "性能消耗较大，旋转角度为0时请取消勾选");
        public static GUIContent MaskAngleText = new GUIContent("旋转角度");
        
        //扭曲贴图
        public static GUIContent DistortionText = new GUIContent("扭曲效果");
        public static GUIContent DistortionTextureText = new GUIContent("扭曲贴图");
        public static GUIContent DistortionIntensityText = new GUIContent("扭曲强度");
        public static GUIContent DistortionUSpeedText = new GUIContent("Distortion_USpeed");
        public static GUIContent DistortionVSpeedText = new GUIContent("Distortion_VSpeed");

        //溶解效果
        public static GUIContent DissolutionText = new GUIContent("溶解效果");
        public static GUIContent DissolutionTextureText = new GUIContent("溶解贴图");
        public static GUIContent DissolvabilityText = new GUIContent("溶解程度");
        public static GUIContent EclosionText = new GUIContent("边缘羽化");
        public static GUIContent EdgeColorText = new GUIContent("边缘颜色","HDR颜色，可用Intensity提高亮度");
        public static GUIContent EdgeWidthText = new GUIContent("边缘宽度");
        public static GUIContent Dissolution_USpeedText = new GUIContent("Dissolution_USpeed");
        public static GUIContent Dissolution_VSpeedText = new GUIContent("Dissolution_VSpeed");

        //渲染队列排序
        public static string advancedText = "Unity's Advanced Options";
    }

    public void FindProperties(MaterialProperty[] props)
    {
        _BlendMode = FindProperty("_BlendMode", props);
        _FaceMode = FindProperty("_FaceMode", props);
        _ZTestMode = FindProperty("_ZTestMode", props);

        _MainTexPopUp = FindProperty("_MainTexPopUp",props);
        _MaskTexPopUp = FindProperty("_MaskTexPopUp",props);
        _DistortionPopUp = FindProperty("_DistortionPopUp",props);
        _DissolutionPopUp = FindProperty("_DissolutionPopUp",props);

        _IsStreamerMode = FindProperty("_IsStreamerMode",props);
        _AlphaValue = FindProperty("_AlphaValue", props);
        _Color = FindProperty("_Color", props);
        _MainTex = FindProperty("_MainTex", props);
        _USpeed = FindProperty("_USpeed",props);
        _VSpeed = FindProperty("_VSpeed", props);
        _LerpColor = FindProperty("_LerpColor", props);
        _LerpValue = FindProperty("_LerpValue", props);
        _DiffuseRotate = FindProperty("_DiffuseRotate", props);
        _DiffuseAngle = FindProperty("_DiffuseAngle", props);
        
        _UseFlicker = FindProperty("_UseFlicker",props);
        _FlickerFrequency = FindProperty("_FlickerFrequency",props);
        _FlickerAmplitude = FindProperty("_FlickerAmplitude",props);

        _DiffuseMask = FindProperty("_DiffuseMask", props);
        _DiffuseMaskLayerShown = FindProperty("_DiffuseMaskLayerShown", props);
        _DiffuseMaskTex = FindProperty("_DiffuseMaskTex", props);
        _Mask_USpeed = FindProperty("_Mask_USpeed", props);
        _Mask_VSpedd = FindProperty("_Mask_VSpeed", props);
        _MaskRotate = FindProperty("_MaskRotate", props);
        _MaskAngle = FindProperty("_MaskAngle", props);

        _Distortion = FindProperty("_Distortion", props);
        _DistortionLayerShown = FindProperty("_DistortionLayerShown", props);
        _DistortionTex = FindProperty("_DistortionTex", props);
        _DistortionIntensity = FindProperty("_DistortionIntensity", props);
        _Distortion_USpeed = FindProperty("_Distortion_USpeed",props);
        _Distortion_VSpeed = FindProperty("_Distortion_VSpeed", props);

        _Dissolution = FindProperty("_Dissolution", props);
        _DissolutionLayerShown = FindProperty("_DissolutionLayerShown", props);
        _DissolutionTex = FindProperty("_DissolutionTex", props);
        _Dissolvability = FindProperty("_Dissolvability", props);
        _Eclosion = FindProperty("_Eclosion", props);
        _EdgeColor = FindProperty("_EdgeColor", props);
        _EdgeWidth = FindProperty("_EdgeWidth", props);
        _Dissolution_USpeed = FindProperty("_Dissolution_USpeed", props);
        _Dissolution_VSpeed = FindProperty("_Dissolution_VSpeed", props);
    }

    //绘制到界面上的方法
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        FindProperties(props);
        m_MaterialEditor = materialEditor;
        Material material = materialEditor.target as Material;
        ShaderPropertiesGUI(material);//主要面板显示方法，在后面有定义
        
    }

    public void ShaderPropertiesGUI(Material material)
    {
        EditorGUIUtility.labelWidth = 0f;
        EditorGUI.BeginChangeCheck();
        {
            EditorGUILayout.BeginVertical(GUILayout.MaxWidth(250));
            BlendModePopup ();
            FaceModePopup();
            ZTestModePopup();
            EditorGUILayout.EndVertical();

            //diffuse
            //m_MaterialEditor.ShaderProperty(_IsStreamerMode, Styles.IsStreamerMode, 0);
            m_MaterialEditor.ShaderProperty(_AlphaValue, Styles.AlphaValueText, 0);
            m_MaterialEditor.ShaderProperty(_Color, Styles.ColorText, 0);

            EditorGUILayout.BeginHorizontal();
            m_MaterialEditor.TexturePropertySingleLine(Styles.BaseTextureText,_MainTex);
            MainTexRGBAPopup();
            EditorGUILayout.EndHorizontal();
            m_MaterialEditor.TextureScaleOffsetProperty(_MainTex);
            m_MaterialEditor.ShaderProperty(_USpeed, Styles.USpeedText, 0);
            m_MaterialEditor.ShaderProperty(_VSpeed, Styles.VSpeedText, 0);
            m_MaterialEditor.ShaderProperty(_LerpColor, Styles.LerpColorText, 0);
            m_MaterialEditor.ShaderProperty(_LerpValue, Styles.LerpValueText, 0);
            m_MaterialEditor.ShaderProperty(_DiffuseRotate, Styles.DiffuseRotateText, 0);
            m_MaterialEditor.ShaderProperty(_DiffuseAngle, Styles.DiffuseAngleText, 0);
            
            m_MaterialEditor.ShaderProperty(_FlickerFrequency,Styles.FlickerFrequency);
            m_MaterialEditor.ShaderProperty(_FlickerAmplitude, Styles.FlickerAmplitude);
        }
        
        Color bCol = GUI.backgroundColor;
        EditorGUILayout.Space();
        GUI.backgroundColor = new Color(1.0f, 1.0f, 1.0f, 0.5f);
        EditorGUILayout.BeginVertical("Button");
        GUI.backgroundColor = bCol;
        {
            EditorGUI.showMixedValue = _UseFlicker.hasMixedValue;
            float nval;
            EditorGUI.BeginChangeCheck();
            if (_UseFlicker.floatValue == 1)
            {
                material.EnableKeyword("_USEFLICKER_ON");
                nval = EditorGUILayout.ToggleLeft(Styles.FlickerToggle, _UseFlicker.floatValue == 1, EditorStyles.boldLabel, GUILayout.Width(EditorGUIUtility.currentViewWidth - 60)) ? 1 : 0;
            }
            else
            {
                material.DisableKeyword("_USEFLICKER_ON");
                nval = EditorGUILayout.ToggleLeft(Styles.FlickerToggle, _UseFlicker.floatValue == 1, EditorStyles.boldLabel) ? 1 : 0;
            }

            if (EditorGUI.EndChangeCheck())
            {
                _UseFlicker.floatValue = nval;
            }
            EditorGUI.showMixedValue = false;

            if (_UseFlicker.floatValue == 1)
            {
                m_MaterialEditor.ShaderProperty(_FlickerFrequency, Styles.FlickerFrequency);
                m_MaterialEditor.ShaderProperty(_FlickerAmplitude, Styles.FlickerAmplitude);
            }
        }
        EditorGUILayout.EndVertical();
        
        //diffuse mask
        GUI.backgroundColor = new Color(1.0f, 1.0f, 1.0f, 0.5f);
        EditorGUILayout.BeginVertical("Button");
        GUI.backgroundColor = bCol;
        {
            EditorGUI.showMixedValue = _DiffuseMask.hasMixedValue;
            float nval;
            EditorGUI.BeginChangeCheck();
            if (_DiffuseMask.floatValue == 1)
            {
                material.EnableKeyword("_DIFFUSEMASK_ON");
                nval = EditorGUILayout.ToggleLeft(Styles.DiffuseMaskText, _DiffuseMask.floatValue == 1, EditorStyles.boldLabel, GUILayout.Width(EditorGUIUtility.currentViewWidth - 60)) ? 1 : 0;
            }
            else
            {
                material.DisableKeyword("_DIFFUSEMASK_ON");
                material.SetTexture("_DiffuseMaskTex", null);
                nval = EditorGUILayout.ToggleLeft(Styles.DiffuseMaskText, _DiffuseMask.floatValue == 1, EditorStyles.boldLabel) ? 1 : 0;
            }

            if (EditorGUI.EndChangeCheck())
            {
                _DiffuseMask.floatValue = nval;
            }
            EditorGUI.showMixedValue = false;
        }
        
        //fold
        if (_DiffuseMask.floatValue == 1)
        {
            Rect rect = GUILayoutUtility.GetLastRect();
            rect.x += EditorGUIUtility.currentViewWidth - 45;
            //rect.height-=EditorGUIUtility.singleLineHeight;

            EditorGUI.BeginChangeCheck();
            float nval = EditorGUI.Foldout(rect, _DiffuseMaskLayerShown.floatValue == 1, "") ? 1 : 0;
            if (EditorGUI.EndChangeCheck())
            {
                _DiffuseMaskLayerShown.floatValue = nval;
            }
        }
        
        //setting
        if (_DiffuseMask.floatValue == 1 && (_DiffuseMaskLayerShown.floatValue == 1 || _DiffuseMaskLayerShown.hasMixedValue))
        {
            EditorGUILayout.BeginHorizontal();
            m_MaterialEditor.TexturePropertySingleLine(Styles.DiffuseMaskTextureText ,_DiffuseMaskTex);
            MaskTexRGBAPopup(); 
            EditorGUILayout.EndHorizontal();

            m_MaterialEditor.TextureScaleOffsetProperty(_DiffuseMaskTex);
            m_MaterialEditor.ShaderProperty(_Mask_USpeed, Styles.MaskUSpeedText, 0);
            m_MaterialEditor.ShaderProperty(_Mask_VSpedd, Styles.MaskVSpeedText, 0);
            m_MaterialEditor.ShaderProperty(_MaskRotate, Styles.MaskRotateText, 0);
            m_MaterialEditor.ShaderProperty(_MaskAngle, Styles.MaskAngleText, 0);
        }
        EditorGUILayout.EndVertical();

        //distortion
        GUI.backgroundColor = new Color(1.0f, 1.0f, 1.0f, 0.5f);
        EditorGUILayout.BeginVertical("Button");
        GUI.backgroundColor = bCol;
        {
            EditorGUI.showMixedValue = _Distortion.hasMixedValue;
            float nval;
            EditorGUI.BeginChangeCheck();
            if (_Distortion.floatValue == 1)
            {
                material.EnableKeyword("_DISTORTION_ON");
                nval = EditorGUILayout.ToggleLeft(Styles.DistortionText, _Distortion.floatValue == 1, EditorStyles.boldLabel, GUILayout.Width(EditorGUIUtility.currentViewWidth - 60)) ? 1 : 0;
            }
            else
            {
                material.DisableKeyword("_DISTORTION_ON");
                material.SetTexture("_DistortionTex", null);
                nval = EditorGUILayout.ToggleLeft(Styles.DistortionText, _Distortion.floatValue == 1, EditorStyles.boldLabel) ? 1 : 0;
            }
            if (EditorGUI.EndChangeCheck())
            {
                _Distortion.floatValue = nval;
            }
            EditorGUI.showMixedValue = false;
        }

        if (_Distortion.floatValue == 1)
        {
            Rect rect = GUILayoutUtility.GetLastRect();
            rect.x += EditorGUIUtility.currentViewWidth - 45;

            EditorGUI.BeginChangeCheck();
            float nval = EditorGUI.Foldout(rect, _DistortionLayerShown.floatValue == 1, "") ? 1 : 0;
            if (EditorGUI.EndChangeCheck())
            {
                _DistortionLayerShown.floatValue = nval;
            }
        }

        if (_Distortion.floatValue == 1 && (_DistortionLayerShown.floatValue == 1 || _DistortionLayerShown.hasMixedValue))
        {
            EditorGUILayout.BeginHorizontal();
            m_MaterialEditor.TexturePropertySingleLine(Styles.DistortionTextureText, _DistortionTex);
            DistortionRGBAPopup();
            EditorGUILayout.EndHorizontal();
            m_MaterialEditor.TextureScaleOffsetProperty(_DistortionTex);
            m_MaterialEditor.ShaderProperty(_DistortionIntensity, Styles.DistortionIntensityText);
            m_MaterialEditor.ShaderProperty(_Distortion_USpeed, Styles.DistortionUSpeedText, 0);
            m_MaterialEditor.ShaderProperty(_Distortion_VSpeed, Styles.DistortionVSpeedText, 0);
        }
        EditorGUILayout.EndVertical();

        //dissolution
        GUI.backgroundColor = new Color(1.0f, 1.0f, 1.0f, 0.5f);
        EditorGUILayout.BeginVertical("Button");
        GUI.backgroundColor = bCol;
        {
            EditorGUI.showMixedValue = _Dissolution.hasMixedValue;
            float nval;
            EditorGUI.BeginChangeCheck();
            if(_Dissolution.floatValue == 1)
            {
                material.EnableKeyword("_DISSOLUTION_ON");
                nval = EditorGUILayout.ToggleLeft(Styles.DissolutionText,_Dissolution.floatValue == 1,EditorStyles.boldLabel,GUILayout.Width(EditorGUIUtility.currentViewWidth-60))?1:0;
            }
            else
            {
                material.DisableKeyword("_DISSOLUTION_ON");
                material.SetTexture("_DissolutionTex", null);
                nval = EditorGUILayout.ToggleLeft(Styles.DissolutionText, _Dissolution.floatValue == 1, EditorStyles.boldLabel) ? 1 : 0;
            }
            if (EditorGUI.EndChangeCheck())
            {
                _Dissolution.floatValue = nval;
            }
            EditorGUI.showMixedValue = false;
        }
        if(_Dissolution.floatValue == 1)
        {
            Rect rect = GUILayoutUtility.GetLastRect();
            rect.x += EditorGUIUtility.currentViewWidth - 45;

            EditorGUI.BeginChangeCheck();
            float nval = EditorGUI.Foldout(rect,_DissolutionLayerShown.floatValue == 1, "") ? 1 : 0;
            if (EditorGUI.EndChangeCheck())
            {
                _DissolutionLayerShown.floatValue = nval;
            }
        }
        if(_Dissolution.floatValue == 1&&(_DissolutionLayerShown.floatValue == 1 || _DissolutionLayerShown.hasMixedValue))
        {
            EditorGUILayout.BeginHorizontal();
            m_MaterialEditor.TexturePropertySingleLine(Styles.DissolutionTextureText, _DissolutionTex);
            DissolutionRGBAPopup();
            EditorGUILayout.EndHorizontal();

            m_MaterialEditor.TextureScaleOffsetProperty(_DissolutionTex);
            m_MaterialEditor.ShaderProperty(_Dissolvability, Styles.DissolvabilityText);
            m_MaterialEditor.ShaderProperty(_Eclosion, Styles.EclosionText, 0);

            m_MaterialEditor.ShaderProperty(_EdgeColor, Styles.EdgeColorText);
            m_MaterialEditor.ShaderProperty(_EdgeWidth, Styles.EdgeWidthText, 0);
            m_MaterialEditor.ShaderProperty(_Dissolution_USpeed, Styles.Dissolution_USpeedText, 0);
            m_MaterialEditor.ShaderProperty(_Dissolution_VSpeed, Styles.Dissolution_VSpeedText, 0);
        }
        EditorGUILayout.EndVertical();

        //set mode
        if (EditorGUI.EndChangeCheck())
        {
            foreach (var obj in _BlendMode.targets)
            {
                SetupMaterialWithBlendMode((Material)obj, (BlendMode)_BlendMode.floatValue);
            }
            foreach (var obj in _FaceMode.targets)
            {
                SetupMaterialWithCullMode((Material)obj, (FaceMode)_FaceMode.floatValue);
            }
            foreach (var obj in _ZTestMode.targets)
            {
                SetupMaterialWithZTestMode((Material)obj, (ZTestMode)_ZTestMode.floatValue);
            }
            foreach (var obj in _MainTexPopUp.targets)
            {
                SetupMaterialWithMainTexRGBA((Material)obj, (MainTexRGBA)_MainTexPopUp.floatValue);
            }
            foreach (var obj in _MaskTexPopUp.targets)
            {
                SetupMaterialWithMaskRGBA((Material)obj, (MaskTexRGBA)_MaskTexPopUp.floatValue);
            }
            foreach (var obj in _DistortionPopUp.targets)
            {
                SetupMaterialWithDistortionRGBA((Material)obj, (DistortionRGBA)_DistortionPopUp.floatValue);
            }
            foreach (var obj in _DissolutionPopUp.targets)
            {
                SetupMaterialWithDissolutionRGBA((Material)obj, (DissolutionRGBA)_DissolutionPopUp.floatValue);
            }
            
            foreach (var obj in _UseFlicker.targets)
            {
                Material mat = (Material)obj;
                if (_UseFlicker.floatValue > 0.5f)
                {
                    mat.EnableKeyword("_USEFLICKER_ON");
                }
                else
                {
                    mat.DisableKeyword("_USEFLICKER_ON");
                }
            }
        }

        //other options
        EditorGUILayout.Space();
        GUILayout.Label(Styles.advancedText, EditorStyles.boldLabel);
        m_MaterialEditor.RenderQueueField();
        m_MaterialEditor.EnableInstancingField();
    }

    void BlendModePopup()
    {
        EditorGUI.showMixedValue = _BlendMode.hasMixedValue;
        var mode = (BlendMode)_BlendMode.floatValue;

        EditorGUI.BeginChangeCheck();
        mode = (BlendMode)EditorGUILayout.Popup(Styles.BlendModeText, (int)mode, Styles.blendNames);
        if (EditorGUI.EndChangeCheck())
        {
            m_MaterialEditor.RegisterPropertyChangeUndo("Rendering Mode");
            _BlendMode.floatValue = (float)mode;

        }
        EditorGUI.showMixedValue = false;
    }

    void FaceModePopup()
    {
        EditorGUI.showMixedValue = _FaceMode.hasMixedValue;
        var mode = (FaceMode)_FaceMode.floatValue;

        EditorGUI.BeginChangeCheck();
        mode = (FaceMode)EditorGUILayout.Popup(Styles.FaceModeText, (int)mode, Styles.faceNames);
        if (EditorGUI.EndChangeCheck())
        {
            m_MaterialEditor.RegisterPropertyChangeUndo("Face Mode");
            _FaceMode.floatValue = (float)mode;
        }

        EditorGUI.showMixedValue = false;

    }
    
    void ZTestModePopup()
    {
        EditorGUI.showMixedValue = _ZTestMode.hasMixedValue;
        var mode = (ZTestMode)_ZTestMode.floatValue;

        EditorGUI.BeginChangeCheck();
        mode = (ZTestMode)EditorGUILayout.Popup(Styles.ZTestModeText, (int)mode, Styles.ztestNames);
        if (EditorGUI.EndChangeCheck())
        {
            m_MaterialEditor.RegisterPropertyChangeUndo("ZTest");
            _ZTestMode.floatValue = (float)mode;
        }

        EditorGUI.showMixedValue = false;
    }


    void MainTexRGBAPopup()
    {
        EditorGUI.showMixedValue = _MainTexPopUp.hasMixedValue;
        var mode = (MainTexRGBA)_MainTexPopUp.floatValue;

        EditorGUI.BeginChangeCheck();
        mode = (MainTexRGBA)EditorGUILayout.Popup( (int)mode, Styles.MainTexRGBAs);
        if (EditorGUI.EndChangeCheck())
        {
            m_MaterialEditor.RegisterPropertyChangeUndo("MainTexMaskMode");
            _MainTexPopUp.floatValue = (float)mode;
        }
        EditorGUI.showMixedValue = false;
    }

    void MaskTexRGBAPopup()
    {
        EditorGUI.showMixedValue = _MaskTexPopUp.hasMixedValue;
        var mode = (MaskTexRGBA)_MaskTexPopUp.floatValue;

        EditorGUI.BeginChangeCheck();
        mode = (MaskTexRGBA)EditorGUILayout.Popup( (int)mode, Styles.MaskTexRGBAs);
        if (EditorGUI.EndChangeCheck())
        {
            m_MaterialEditor.RegisterPropertyChangeUndo("MaskTexMaskMode");
            _MaskTexPopUp.floatValue = (float)mode;
        }
        EditorGUI.showMixedValue = false;
    }

    void DistortionRGBAPopup()
    {
        EditorGUI.showMixedValue = _DistortionPopUp.hasMixedValue;
        var mode = (DistortionRGBA)_DistortionPopUp.floatValue;

        EditorGUI.BeginChangeCheck();
        mode = (DistortionRGBA)EditorGUILayout.Popup( (int)mode, Styles.DistortionRGBAs);
        if (EditorGUI.EndChangeCheck())
        {
            m_MaterialEditor.RegisterPropertyChangeUndo("DistortionTexMaskMode");
            _DistortionPopUp.floatValue = (float)mode;
        }
        EditorGUI.showMixedValue = false;
    }
    
    void DissolutionRGBAPopup()
    {
        EditorGUI.showMixedValue = _DissolutionPopUp.hasMixedValue;
        var mode = (DissolutionRGBA)_DissolutionPopUp.floatValue;

        EditorGUI.BeginChangeCheck();
        mode = (DissolutionRGBA)EditorGUILayout.Popup( (int)mode, Styles.DissolutionRGBAs);
        if (EditorGUI.EndChangeCheck())
        {
            m_MaterialEditor.RegisterPropertyChangeUndo("DissolutionTexMaskMode");
            _DissolutionPopUp.floatValue = (float)mode;
        }
        EditorGUI.showMixedValue = false;
    }

    static void SetupMaterialWithBlendMode(Material material, BlendMode blendMode)
    {
        switch (blendMode)
        {
            case BlendMode.Add:
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.One);
                break;
            case BlendMode.Transparent:
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                break;
        }
    }

    static void SetupMaterialWithCullMode(Material material, FaceMode cullMode)
    {
        switch (cullMode)
        {
            case FaceMode.One:
                material.SetInt("_CullMode", (int)UnityEngine.Rendering.CullMode.Back);
                break;
            case FaceMode.Two:
                material.SetInt("_CullMode", (int)UnityEngine.Rendering.CullMode.Off);
                break;
        }
    }

    static void SetupMaterialWithZTestMode(Material material, ZTestMode ztest)
    {
        switch (ztest)
        {
            case ZTestMode.On:
                material.SetInt("_ZTest", 4);
                break;
            case ZTestMode.Off:
                material.SetInt("_ZTest", 8);
                break;
        }
    }

    static void SetupMaterialWithMainTexRGBA(Material material, MainTexRGBA maintexrgba)
    {
        switch (maintexrgba)
        {
            case MainTexRGBA.RGB:
                material.SetInt("_ColorSwitch",0); 
                break;
            case MainTexRGBA.R:
                material.SetInt("_ColorSwitch",1); 
                material.SetVector("_MainTexRGBA", new Vector4(1,0,0,0));
                break;
            case MainTexRGBA.G:
                material.SetInt("_ColorSwitch",1); 
                material.SetVector("_MainTexRGBA", new Vector4(0,1,0,0));
                break;
            case MainTexRGBA.B:
                material.SetInt("_ColorSwitch",1); 
                material.SetVector("_MainTexRGBA", new Vector4(0,0,1,0));
                break;
            case MainTexRGBA.A:
                material.SetInt("_ColorSwitch",1); 
                material.SetVector("_MainTexRGBA", new Vector4(0,0,0,1));
                break;
        }
    }
    static void SetupMaterialWithMaskRGBA(Material material, MaskTexRGBA maskrgba)
    {
        switch (maskrgba)
        {
            case MaskTexRGBA.R:
                material.SetVector("_MaskTexRGBA", new Vector4(1,0,0,0));
                break;
            case MaskTexRGBA.G:
                material.SetVector("_MaskTexRGBA", new Vector4(0,1,0,0));
                break;
            case MaskTexRGBA.B:
                material.SetVector("_MaskTexRGBA", new Vector4(0,0,1,0));
                break;
            case MaskTexRGBA.A:
                material.SetVector("_MaskTexRGBA", new Vector4(0,0,0,1));
                break;
        }
    }
    static void SetupMaterialWithDistortionRGBA(Material material, DistortionRGBA maskrgba)
    {
        switch (maskrgba)
        {
            case DistortionRGBA.R:
                material.SetVector("_DistortionRGBA", new Vector4(1,0,0,0));
                break;
            case DistortionRGBA.G:
                material.SetVector("_DistortionRGBA", new Vector4(0,1,0,0));
                break;
            case DistortionRGBA.B:
                material.SetVector("_DistortionRGBA", new Vector4(0,0,1,0));
                break;
            case DistortionRGBA.A:
                material.SetVector("_DistortionRGBA", new Vector4(0,0,0,1));
                break;
        }
    }
    static void SetupMaterialWithDissolutionRGBA(Material material, DissolutionRGBA maskrgba)
    {
        switch (maskrgba)
        {
            case DissolutionRGBA.R:
                material.SetVector("_DissolutionRGBA", new Vector4(1,0,0,0));
                break;
            case DissolutionRGBA.G:
                material.SetVector("_DissolutionRGBA", new Vector4(0,1,0,0));
                break;
            case DissolutionRGBA.B:
                material.SetVector("_DissolutionRGBA", new Vector4(0,0,1,0));
                break;
            case DissolutionRGBA.A:
                material.SetVector("_DissolutionRGBA", new Vector4(0,0,0,1));
                break;
        }
    }

}
