using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TerrainBaker : MonoBehaviour
{

    public RenderTexture ColorTexture;
    public Camera Camera;
    
    [ContextMenu("Bake Texture")]
    public void Bake()
    {
        Camera.targetTexture = ColorTexture;
        Camera.Render();
    }

}
