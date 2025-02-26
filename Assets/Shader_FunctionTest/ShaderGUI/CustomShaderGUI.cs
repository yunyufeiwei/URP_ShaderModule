using UnityEngine;
using UnityEditor;
using UnityEditor.AnimatedValues;

public class CustomShaderGUI : ShaderGUI
{
    #region [属性成员]
    Material mat;

    MaterialProperty floatProp;
    MaterialProperty rangeProp;
    bool isFloatEnabled;

    MaterialProperty vectorProp;
    int vectorPropX;
    float vectorPropY;
    float vectorPropZ;
    float vectorPropW;
    bool isVectorEnabled;

    MaterialProperty baseColorProp;
    MaterialProperty baseMapProp;
    AnimBool animBool01 = new AnimBool(true);

    MaterialProperty saveValue01Prop;
    #endregion

    //当重新定义绘制GUI方法，不填写任何内容时，材质面板显示会是空白
    override public void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        /*----------------------------------------------浮点块--------------------------------------------------------------------*/

        //#region与#endregion是成对出现，用来方便折叠管理代码块
        #region [浮点数]

        saveValue01Prop = FindProperty("_SaveValue01", properties);
        //使用if条件语句来判断isFloatEnabled这个布尔值，其中saveValue01Prop.vectorValue的数值在下面的数据保存栏进行了重定义
        // if(saveValue01Prop.vectorValue.x != 0)
        // {
        //     isFloatEnabled = true;
        // }
        // else
        // {
        //     isFloatEnabled = false;
        // }
        //使用三目运算符进行替换if条件判断语句
        isFloatEnabled = saveValue01Prop.vectorValue.x != 0 ? true : false;
        isFloatEnabled = EditorGUILayout.Foldout(isFloatEnabled, "折叠开关组");

        if (isFloatEnabled)
        {
            //LabelField按模块分类语法，将不同类型的参数按块分割，第一个参数是显示在面板上的名字，第二个参数是字体的样式，例如变黑
            EditorGUILayout.LabelField("常量数值", EditorStyles.boldLabel);

            //添加方框的开始点
            EditorGUILayout.BeginVertical(EditorStyles.helpBox);

            //通过FindProperty获取材质shader里面定义的属性，将shader的属性值保存在定义的floatProp参数中
            floatProp = FindProperty("_Float", properties);
            //materialEditor.FloatProperty将定义的属性（浮点数）绘制在材质的面板，第一个参数是从shader中获取的值保存在定义的floatProp中，第二给参数是在材质面板上显示名
            materialEditor.FloatProperty(floatProp, "浮点数");
            //添加条件判断，如果大于5，则会出现文字提示
            if (floatProp.floatValue > 5)
            {
                //MessageType下的方法来选择文字提示的类型(Error/Info/None/Warning),不同的选择，提示的图标显示不同
                EditorGUILayout.HelpBox("尽量不要超过5,否则会出现效果不太好的情况~~", MessageType.Warning);
            }

            rangeProp = FindProperty("_Range", properties);
            materialEditor.RangeProperty(rangeProp, "滑动条");

            //添加方框的结束点
            EditorGUILayout.EndVertical();
        }

        #endregion

        #region 
        /*----------------------------------------------向量块--------------------------------------------------------------------*/
        //Space方法将调整不同模块之间的间距
        EditorGUILayout.Space(20);

        mat = materialEditor.target as Material;

        isVectorEnabled = mat.IsKeywordEnabled("_VECTORENABLED_ON") ? true : false;
        ////Toggle分组的开始语句
        isVectorEnabled = EditorGUILayout.BeginToggleGroup("四维向量开关", isVectorEnabled);

        if (isVectorEnabled)
        {
            mat.EnableKeyword("_VECTORENABLED_ON");
        }
        else
        {
            mat.DisableKeyword("_VECTORENABLED_ON");
        }

        //绘制四维向量的模块显示部分
        EditorGUILayout.LabelField("四维向量", EditorStyles.boldLabel);
        //通过FindProperty获取材质shader里面定义的属性，将shader的属性值保存在定义的floatProp参数中
        vectorProp = FindProperty("_Vector", properties);
        //materialEditor.VectorProperty将定义的属性（向量）绘制在材质的面板，第一个参数是从shader中获取的值保存在定义的floatProp中，第二给参数是在材质面板上显示名
        materialEditor.VectorProperty(vectorProp, "四维向量");

        EditorGUILayout.HelpBox("四维向量可以通过EditorGUILayout分拆成不同的值", MessageType.None);
        //一定要去读取材质属性中的值，要不然属性值会被默认值覆盖,导致每次重新选中材质球时，参数值会还原为默认值
        vectorPropX = (int)vectorProp.vectorValue.x;
        vectorPropY = vectorProp.vectorValue.y;
        vectorPropZ = vectorProp.vectorValue.z;
        vectorPropW = vectorProp.vectorValue.w;
        //EditorGUILayout写法，显示在材质面板上的方式
        vectorPropX = EditorGUILayout.IntField("整型(EditorGUILayout)", vectorPropX);
        vectorPropY = EditorGUILayout.Slider("滑动条(EditorGUILayout)", vectorPropY, 0, 5);
        EditorGUILayout.MinMaxSlider("范围滑动条(EditorGUILayout)", ref vectorPropZ, ref vectorPropW, 0, 5);
        //将重新输入的参数组装成一个四维向量
        Vector4 _newVector = new Vector4(vectorPropX, vectorPropY, vectorPropZ, vectorPropW);
        //将拆分之后组成的新的Vector变量存储到原始的Vector中
        vectorProp.vectorValue = _newVector;

        EditorGUILayout.EndToggleGroup();
        #endregion

        /*----------------------------------------------颜色块--------------------------------------------------------------------*/
        EditorGUILayout.Space(20);

        animBool01.target = saveValue01Prop.vectorValue.y != 0 ? true : false;
        animBool01.target = EditorGUILayout.Foldout(animBool01.target, "带折叠的动画效果",EditorStyles.boldFont);
        if (EditorGUILayout.BeginFadeGroup(animBool01.faded))
        {
            EditorGUILayout.LabelField("颜色和纹理", EditorStyles.boldLabel);
            //颜色属性重新绘制
            baseColorProp = FindProperty("_Color", properties);
            materialEditor.ColorProperty(baseColorProp, "颜色(materialEditor)");

            //贴图属性重新指定
            baseMapProp = FindProperty("_BaseMap", properties);
            //贴图GUI不同类型绘制
            materialEditor.TextureProperty(baseMapProp, "纹理贴图(materialEditor)");
            materialEditor.TexturePropertySingleLine(new GUIContent("单行纹理"), baseMapProp);
            EditorGUILayout.Space(10);
            materialEditor.TexturePropertyTwoLines(new GUIContent("两行纹理(materialEditor)"), baseMapProp, baseColorProp, new GUIContent("第二行属性"), vectorProp);
            EditorGUILayout.Space(20);
            materialEditor.TexturePropertyWithHDRColor(new GUIContent("HDR+纹理(materialEditor)"), baseMapProp, baseColorProp, false);
            EditorGUILayout.Space(20);
            materialEditor.TextureScaleOffsetProperty(baseMapProp);
        }
        EditorGUILayout.EndFadeGroup();

        //数据保存(这里保存的数据用在使用四维向量来保存布尔值)
        float saveValue01X = isFloatEnabled ? 1 : 0;
        float saveValue01Y = animBool01.target ? 1 : 0;
        Vector4 saveValue01 = new Vector4(saveValue01X, saveValue01Y, 0, 0);
        saveValue01Prop.vectorValue = saveValue01;

        //额外选项
        EditorGUILayout.Space(20);
        EditorGUILayout.BeginVertical(new GUIStyle("box"));
        //渲染设置的一些其它选项
        //渲染队列设置
        materialEditor.RenderQueueField();
        materialEditor.EnableInstancingField();
        materialEditor.DoubleSidedGIField();
        EditorGUILayout.EndVertical();


    }
}
