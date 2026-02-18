Shader "Unlit/Shader2"
{
    Properties
    {
        _ColorA ("Color A", Color) = (1.0, 1.0, 1.0, 1.0)
        _ColorB ("Color B", Color) = (1.0, 1.0, 1.0, 1.0)
        _ColorStart ("Color Start", Range(0.0, 1.0)) = 0.0
        _ColorEnd ("Color End", Range(0.0, 1.0)) = 0.0
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _ColorA;
            float4 _ColorB;
            float _ColorStart;
            float _ColorEnd;

            float invlerp(float a, float b, float v)
            {
                return saturate((v - a) / (b - a));
            }

            struct MeshData
            {
                float4 vertex : POSITION; // Vertex local position
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION; // Clip space position
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
            };

            Interpolators vert(MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex); // Converts local space position to clip space position
                o.uv = v.uv;
                o.normal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));
                return o;
            }

            float4 frag(Interpolators i) : SV_Target
            {
                float t = invlerp(_ColorStart, _ColorEnd, i.uv.x);
                float4 color = lerp(_ColorA, _ColorB, t);
                return color;
            }
            ENDCG
        }
    }
}