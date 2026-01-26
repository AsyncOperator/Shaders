using System.Collections.Generic;
using UnityEngine;

public class PlaneGenerator : MonoBehaviour
{
    [SerializeField] private MeshFilter m_MeshFilter;

    private Mesh m_Mesh;

    [ContextMenu("Generate Plane")]
    private void GeneratePlane()
    {
        if (m_Mesh == null)
        {
            m_Mesh = new Mesh();
        }

        m_MeshFilter.sharedMesh = m_Mesh;

        const int vertex_count_along_axis = 65;

        List<Vector3> verts = new List<Vector3>();
        List<Vector2> uvs = new List<Vector2>();
        List<int> tris = new List<int>();
        for (int i = 0; i < vertex_count_along_axis; i++)
        {
            for (int j = 0; j < vertex_count_along_axis; j++)
            {
                Vector3 vert = new Vector3(-0.5f, 0.0f, -0.5f);
                vert += new Vector3(i / (vertex_count_along_axis - 1.0f), 0.0f, j / (vertex_count_along_axis - 1.0f));

                verts.Add(vert);

                Vector2 uv = new Vector2(i / (vertex_count_along_axis - 1.0f), j / (vertex_count_along_axis - 1.0f));
                uvs.Add(uv);

                if (i < (vertex_count_along_axis - 1) && j < (vertex_count_along_axis - 1))
                {
                    int root = i * vertex_count_along_axis + j;
                    int rootNeighbour = root + vertex_count_along_axis;
                    int next = root + 1;
                    int nextNeighbour = next + vertex_count_along_axis;

                    tris.Add(root);
                    tris.Add(next);
                    tris.Add(nextNeighbour);

                    tris.Add(root);
                    tris.Add(nextNeighbour);
                    tris.Add(rootNeighbour);
                }
            }
        }

        m_Mesh.Clear();

        m_Mesh.SetVertices(verts);
        m_Mesh.SetTriangles(tris, 0);
        m_Mesh.SetUVs(0, uvs);
        m_Mesh.RecalculateNormals();
    }
}