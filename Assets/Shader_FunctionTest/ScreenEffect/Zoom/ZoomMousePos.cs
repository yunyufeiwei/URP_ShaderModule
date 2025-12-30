// using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;

public class ZoomMousePos : MonoBehaviour
{
    public GameObject volume;
    public Vector2 pos;

    private void Start()
    {
        volume = GetComponent<GameObject>();
    }

    void Update()
    {
        if (Input.GetMouseButton(0))
        {
            Vector2 mousePos = Input.mousePosition;
            pos = new Vector2(mousePos.x / Screen.width, mousePos.y / Screen.height);
        }
    }
}
