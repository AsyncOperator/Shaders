Shader "Unlit/Painting"
{
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

            StructuredBuffer<float4> _ColorBuffer;

            struct MeshData
            {
                float4 vertex : POSITION;
                uint id : SV_VertexID;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
            };

            Interpolators vert(MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.color = _ColorBuffer[v.id];
                return o;
            }

            float4 frag(Interpolators i) : SV_Target
            {
                return i.color;
            }
            ENDCG
        }
    }
}