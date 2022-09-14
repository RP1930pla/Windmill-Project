using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEditorInternal;

public class QSelect : EditorWindow
{
    GameObject[] list;
    int tagindex;
    string[] tagarray;

    [MenuItem("QActions/QSelect")]

    public static void ShowWindow()
    {
        GetWindow<QSelect>("QSelect");
    }

    private void OnGUI()
    {
        GUILayout.Label("Select by Tag",EditorStyles.boldLabel);
        tagarray = UnityEditorInternal.InternalEditorUtility.tags;
        tagindex = EditorGUILayout.Popup(tagindex, tagarray);
        if (GUILayout.Button("Select objects marked with tag"))
        {
            list = GameObject.FindGameObjectsWithTag(tagarray[tagindex]);
            Selection.objects = list;
        }    
    }





}


