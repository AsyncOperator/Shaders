Shader "Hidden/Roystan/Normals Texture"
{
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct MeshData
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
                float3 viewNormal : NORMAL;
            };

            Interpolators vert(MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.viewNormal = COMPUTE_VIEW_NORMAL;
                return o;
            }

            float4 frag(Interpolators i) : SV_Target
            {
                return float4(i.viewNormal, 0);
            }
            ENDCG
        }
    }
}