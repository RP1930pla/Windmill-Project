using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEditorInternal;


public enum OPTIONS
{
    
}
public class QRenamer : EditorWindow
{

    string newname;
    string[] tagarray;
    int tagindex;


    [MenuItem("QActions/QRename")]
    public static void ShowWindow()
    {
        GetWindow<QRenamer>("QRename");
    }


    private void OnGUI()
    {


        tagarray = GetAllTags();

        if (Selection.count == 0)
        {
            GUILayout.Label("Select GameObjects first", EditorStyles.helpBox);
        }
        else
        {
            GUILayout.Label("New GameObject Name", EditorStyles.boldLabel);
            newname = EditorGUILayout.TextArea(newname);
            if (GUILayout.Button("Rename!")){
                int number = 0;
                foreach(GameObject i in Selection.gameObjects)
                {
                    if (number == 0)
                    {
                        i.name = newname;
                        number++;
                    }
                    else
                    {
                        i.name = newname + "_" + number;
                        number++;
                    }
                }
            }

            GUILayout.Space(5f);
            GUILayout.Label("Tag Change", EditorStyles.boldLabel);
            tagindex = EditorGUILayout.Popup(tagindex, tagarray);

            if (GUILayout.Button("Change GameObject Tag"))
            {
                foreach (GameObject i in Selection.gameObjects)
                {
                    i.tag = tagarray[tagindex];
                }
            }
            
        }







    }


    string[] GetAllTags()
    {
        return UnityEditorInternal.InternalEditorUtility.tags;
    }



}
