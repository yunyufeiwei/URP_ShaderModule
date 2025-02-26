using UnityEngine;

//含有抽象方法的类必须被声明为抽象类，并且不能被实例化。这个方法的实现将由继承这个抽象类的子类提供。
public abstract class Transformation : MonoBehaviour
{
    //定义一个名为Apply的抽象方法，它接收一个Vector3类型的参数point，并返回一个Vector3类型的结果。
    //abstract：这个关键字表明Apply是一个抽象方法。抽象方法没有方法体（即没有大括号{}中的代码），它们仅定义方法的签名。
    //public abstract Vector3 Apply(Vector3 point);

    //矩阵法
    //定义一个抽象属性Matrix，返回类型为Materix4x4，这个属性需要再继承的子类中实现，通过用于表示一个变换矩阵
    public abstract Matrix4x4 Matrix { get; }
    //抽象类里面也可以不使用抽象方法，这个时候就需要将方法添加方法体与返回值。
    public Vector3 Apply(Vector3 point)
    {
        return Matrix.MultiplyPoint(point);
    }
}
