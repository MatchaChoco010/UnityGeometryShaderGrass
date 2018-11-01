using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
public class Grass : MonoBehaviour
{

    public LayerMask mask;
    public float length = 2;

    private Mesh mesh;
    private List<Vector3> vertices = new List<Vector3>();
    private List<Color> colors = new List<Color>();
    private Ray[] rays;

    void Start()
    {
        mesh = GetComponent<MeshFilter>().sharedMesh;
        mesh.GetVertices(vertices);

        rays = new Ray[vertices.Count];

        for (var i = 0; i < vertices.Count; i++){
            var pos = gameObject.transform.localToWorldMatrix * vertices[i];
            rays[i] = new Ray(pos , Vector3.up);
        }

        for (var i = 0; i < vertices.Count; i++){
            colors.Add(new Color(1, 1, 1, 1));
        }

        mesh.SetColors(colors);
    }

    void Update()
    {
        for (var i = 0; i < vertices.Count; i++){
            if (Physics.Raycast(rays[i], out var hit, length, mask)) {
                colors[i] = new Color(0.2f, 1, 1, 1);
            }
        }

        mesh.SetColors(colors);
    }
}
