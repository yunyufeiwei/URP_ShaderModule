using UnityEngine;

// [ExecuteInEditMode]
public class AxisWorldPosition : MonoBehaviour
{
    public GameObject model = null;

    private Transform modelTransform = null;
    private Material mat = null;
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        modelTransform = GetComponent<Transform>();
        mat = this.GetComponent<Renderer>().material;
    }

    // Update is called once per frame
    void Update()
    {
        // float3 newPosition = modelTransform.position;
        mat.SetVector("_axisPos",modelTransform.position);
    }
}
