Shader "Unlit/MySkybox"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Background"
            "Queue"="Background"
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;

            float2 dirtorectilinear(float3 d)
            {
                // Returns between [PI, -PI] need to remap into [0, 1]
                float x = (atan2(d.z, d.x) / UNITY_PI) * 0.5 + 0.5;
                float y = d.y * 0.5 + 0.5;
                return float2(x, y);
            }

            struct MeshData
            {
                float4 vertex : POSITION;
                float3 view_dir : TEXCOORD0;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
                float3 view_dir : TEXCOORD0;
            };

            Interpolators vert(MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.view_dir = v.view_dir;
                return o;
            }

            float4 frag(Interpolators i) : SV_Target
            {
                float2 uv = dirtorectilinear(i.view_dir);
                return tex2Dlod(_MainTex, float4(uv, 0, 0));
            }
            ENDCG
        }
    }
}