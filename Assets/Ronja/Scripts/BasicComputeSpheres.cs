using UnityEngine;

public class BasicComputeSpheres : MonoBehaviour
{
    private static readonly int s_ResultPropertyID = Shader.PropertyToID("Result");
    private static readonly int s_TimePropertyID = Shader.PropertyToID("Time");

    [SerializeField, Min(1)] private int m_SphereAmount;
    [SerializeField] private ComputeShader m_ComputeShader;

    private ComputeBuffer m_ResultBuffer;
    private int m_Kernel;
    private uint m_ThreadGroupSize;
    private Vector3[] m_Output;
    private Transform[] m_Instances;

    private void OnDestroy()
    {
        m_ResultBuffer?.Dispose();
        m_ResultBuffer = null;
    }

    private void Start()
    {
        Debug.Log("System support compute shaders: " + SystemInfo.supportsComputeShaders);

        m_Kernel = m_ComputeShader.FindKernel("Spheres");
        m_ComputeShader.GetKernelThreadGroupSizes(m_Kernel, out m_ThreadGroupSize, out _, out _);

        m_ResultBuffer = new ComputeBuffer(m_SphereAmount, sizeof(float) * 3);
        m_Output = new Vector3[m_SphereAmount];
        m_Instances = new Transform[m_SphereAmount];

        for (int i = 0; i < m_SphereAmount; i++)
        {
            m_Instances[i] = GameObject.CreatePrimitive(PrimitiveType.Sphere).transform;
        }
    }

    private void Update()
    {
        m_ComputeShader.SetBuffer(m_Kernel, s_ResultPropertyID, m_ResultBuffer);
        m_ComputeShader.SetFloat(s_TimePropertyID, Time.time);
        int threadGroups = (int)((m_SphereAmount + (m_ThreadGroupSize - 1)) / m_ThreadGroupSize);
        m_ComputeShader.Dispatch(m_Kernel, threadGroups, 1, 1);
        m_ResultBuffer.GetData(m_Output);

        for (int i = 0; i < m_SphereAmount; i++)
        {
            m_Instances[i].position = transform.TransformPoint(m_Output[i]);
        }
    }
}