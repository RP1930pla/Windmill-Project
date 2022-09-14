using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEditorInternal;
using UnityEngine.UI;

public class CloudEditor : EditorWindow
{
    GameObject PlaneOBJ;
    int MeshCount;
    float TotalSpace;

    GameObject Master;
    float LocalScale = 1f;

    MaterialPropertyBlock Parameters;
    [MenuItem("Anima/Anima Cloud Editor")]
    public static void ShowWindow()
    {
        GetWindow<CloudEditor>("Cloud Editor");
    }

    private void OnGUI()
    {
        GUILayout.Label("Cloud Plane Mesh", EditorStyles.boldLabel);
        GUILayout.Space(5f);
        PlaneOBJ = EditorGUILayout.ObjectField("Mesh to create", PlaneOBJ, typeof(GameObject), false) as GameObject;

        GUILayout.Space(5f);
        GUILayout.Label("Instancing Parameters", EditorStyles.boldLabel);
        GUILayout.BeginHorizontal();
        TotalSpace = EditorGUILayout.FloatField("Width", TotalSpace);
        MeshCount = EditorGUILayout.IntSlider("Plane Count",MeshCount, 4, 32);

        if (GUILayout.Button("Spawn Clouds"))
        {
            Spawn();
            Debug.Log(MeshCount + " planes created");
        }
        GUILayout.EndHorizontal();

        GUILayout.Space(5f);
        if (Master == null)
        {
            GUILayout.BeginHorizontal();
            Master = GameObject.Find("Clouds");
            GUILayout.Label("No clouds created", EditorStyles.helpBox);
            GUILayout.EndHorizontal();
        }
        else
        {
            GUILayout.BeginVertical();
            GUILayout.Label("Edit Clouds", EditorStyles.boldLabel);
            LocalScale = EditorGUILayout.FloatField("Scale", LocalScale);
            Master.transform.localScale = new Vector3(LocalScale,1f,LocalScale);
            GUILayout.EndVertical();
        }
        
    }


    void Spawn()
    {
        GameObject EmptyObj;
        if (PlaneOBJ == null)
        {
            Debug.Log("No mesh provided");
        }
        else
        {
            EmptyObj = new GameObject("Clouds");
            
            for(int i=0; i<MeshCount; i++)
            {
                MeshRenderer Rend;

                if (Parameters == null)
                {
                    Parameters = new MaterialPropertyBlock();
                }
                
                GameObject Instance = Instantiate(PlaneOBJ, new Vector3(0,(TotalSpace/MeshCount)*i,0), Quaternion.identity);

                Instance.name = "Cloud_" + i;

                Rend = Instance.GetComponent<MeshRenderer>();

                float Slice = 1f / MeshCount;
                //Rend.GetPropertyBlock(Parameters);
                //Parameters.SetFloat("_Slice", Slice*(i+1));
                //Rend.SetPropertyBlock(Parameters);

                Rend.material.SetFloat("_Slice", Slice*(i+1));
                Instance.transform.parent = EmptyObj.transform;

            }
        }
    }




}
