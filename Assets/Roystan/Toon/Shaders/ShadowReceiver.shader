Shader "Roystan/Shadow Receiver"
{
    Properties
    {
        _Alpha("Alpha", Range(0, 1)) = 1
    }
    SubShader
    {
        Pass
        {
            Tags
            {
                "Queue" = "Geometry+1"
            }

            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            float _Alpha;
            
            struct MeshData
            {
                float4 vertex : POSITION;
            };

            struct Interpolators
            {
                float4 pos : SV_POSITION;
                SHADOW_COORDS(0)
            };

            Interpolators vert(MeshData v)
            {
                Interpolators o;
                o.pos = UnityObjectToClipPos(v.vertex);
                TRANSFER_SHADOW(o)
                return o;
            }

            float4 frag(Interpolators i) : SV_Target
            {
                float shadow = SHADOW_ATTENUATION(i);
                return float4(0, 0, 0, (1 - shadow) * _Alpha);
            }
            ENDCG
        }

        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}