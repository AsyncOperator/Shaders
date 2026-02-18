Shader "Unlit/Shader3"
{
    Properties
    {
        [Toggle] _ApplyOffset ("Apply Offset", Integer) = 0
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

            int _ApplyOffset;

            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
            };

            Interpolators vert(MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));
                return o;
            }

            float4 frag(Interpolators i) : SV_Target
            {
                float time = _Time.x;
                float offset = _ApplyOffset * cos((i.uv.y) * UNITY_TWO_PI * 8.0F) * 0.01F;
                
                float t = abs(frac(i.uv.x * 5.0F + 0.5F) * 2.0F - 1.0F);

                // t = sin((i.uv.x + offset + time) * UNITY_TWO_PI * 6 - UNITY_HALF_PI) * 0.5F + 0.5F;
                t = cos((i.uv.x + offset + time) * UNITY_TWO_PI * 4.0F - UNITY_PI) * 0.5F + 0.5F;

                return t;
            }
            ENDCG
        }
    }
}