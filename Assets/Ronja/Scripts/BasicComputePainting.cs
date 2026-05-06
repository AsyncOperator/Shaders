using Unity.Collections;
using UnityEngine;

public class BasicComputePainting : MonoBehaviour
{
    [SerializeField] private ComputeShader m_ComputeShader;
    [SerializeField] private Transform m_PaintingSphere;
    [SerializeField] private float m_PaintRadius;

    private Mesh m_Mesh;
    private Material m_Material;
    private int m_VertexCount;

    private int m_KernelID;
    private int m_ThreadGroupSize;
    private ComputeBuffer m_VertexBuffer;
    private ComputeBuffer m_ColorBuffer;

    private void OnEnable()
    {
        m_Mesh = GetComponent<MeshFilter>().sharedMesh;
        m_Material = GetComponent<MeshRenderer>().sharedMaterial;
        m_VertexCount = m_Mesh.vertexCount;

        m_VertexBuffer = new ComputeBuffer(m_VertexCount, sizeof(float) * 3);
        m_ColorBuffer = new ComputeBuffer(m_VertexCount, sizeof(float) * 4);

        m_KernelID = m_ComputeShader.FindKernel("CSMain");
        m_ComputeShader.GetKernelThreadGroupSizes(m_KernelID, out uint threadX, out _, out _);

        // The number of thread groups we’ll end up using are going to be equal to
        // however many iterations we want the compute shader to run for,
        // divided by the thread group size. We then take the ceiling of the result.
        // So, in this case, if we have 48 vertices and a kernel with a thread group size of 32 on the X, we’d need 2 groups to run.
        m_ThreadGroupSize = Mathf.CeilToInt((float)m_VertexCount / threadX);

        using (Mesh.MeshDataArray meshDataArray = Mesh.AcquireReadOnlyMeshData(m_Mesh))
        {
            Mesh.MeshData meshData = meshDataArray[0];
            using (NativeArray<Vector3> nativeArray = new NativeArray<Vector3>(m_VertexCount, Allocator.TempJob, NativeArrayOptions.UninitializedMemory))
            {
                meshData.GetVertices(nativeArray);
                m_VertexBuffer.SetData(nativeArray);
            }
        }

        m_ComputeShader.SetBuffer(m_KernelID, "_VertexBuffer", m_VertexBuffer);
        m_ComputeShader.SetBuffer(m_KernelID, "_ColorBuffer", m_ColorBuffer);
        m_ComputeShader.SetInt("_VertexCount", m_VertexCount);

        m_Material.SetBuffer("_ColorBuffer", m_ColorBuffer);
    }

    private void OnDisable()
    {
        m_VertexBuffer?.Dispose();
        m_VertexBuffer = null;

        m_ColorBuffer?.Dispose();
        m_ColorBuffer = null;
    }

    private void Update()
    {
        m_ComputeShader.SetMatrix("_LocalToWorld", transform.localToWorldMatrix);
        m_ComputeShader.SetVector("_Sphere", new Vector4(m_PaintingSphere.position.x, m_PaintingSphere.position.y, m_PaintingSphere.position.z, m_PaintRadius));
        m_ComputeShader.Dispatch(m_KernelID, m_ThreadGroupSize, 1, 1);
    }

    private void OnDrawGizmos()
    {
        if (m_PaintingSphere != null)
        {
            Gizmos.DrawSphere(m_PaintingSphere.position, m_PaintRadius);
        }
    }
}