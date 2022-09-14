using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEditorInternal;

public class FogEditor : EditorWindow
{

    Material Mat;


    [MenuItem("Anima/Anima Lightning/Fog Ambiance")]
    public static void ShowWindow()
    {
        GetWindow<FogEditor>("Fog Editor");
    }

    
    private void OnGUI()
    {
        string[] guids;
        guids = AssetDatabase.FindAssets("l:ExponentialFog", new[] { "Assets/Anima" });
        string path;
        path = AssetDatabase.GUIDToAssetPath(guids[0]);
        Mat = (Material)AssetDatabase.LoadAssetAtPath(path, typeof (Material));
        Debug.Log(guids);

    }
}
