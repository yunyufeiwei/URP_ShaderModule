using System;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable, VolumeComponentMenu("CustomPostProcess/RadialBlur")]
public class RadialBlurVolume : VolumeComponent, IPostProcessComponent
{
    // 是否启用
    public BoolParameter isUse = new BoolParameter(false, BoolParameter.DisplayType.Checkbox);

    // 模糊强度 (0~1)
    public ClampedFloatParameter blurStrength = new ClampedFloatParameter(0.0f, 0.0f, 1.0f);

    // 采样迭代次数 (越高质量越好，性能消耗越大)
    public ClampedIntParameter iterations = new ClampedIntParameter(8, 2, 30);

    public bool IsActive() => isUse.value && blurStrength.value > 0f;
    public bool IsTileCompatible() => false;
}
