Shader "Unlit/Shader6"
{
    Properties
    {
        _RippleAmp ("Ripple Amplitude", Range(0.01, 0.2)) = 0.1
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

            float _RippleAmp;

            float getripple(float2 uv)
            {
                // UV's are in normalized space which is range between [0, 1], we are remapping it to turn into [-1, 1] range
                // so that UV at (0.5, 0.5) becomes the origin (0, 0)
                float2 uvcentered = uv * 2.0F - 1.0F;
                float len = length(uvcentered);

                float ripple = cos((len - _Time.x) * UNITY_TWO_PI * 7.0F) * 0.5F + 0.5F;
                float mult = saturate(1.0F - len);
                return ripple * mult;
            }

            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Interpolators vert(MeshData v)
            {
                float ripple = getripple(v.uv);
                float3 vertoffset = float3(0.0F, ripple * _RippleAmp, 0.0F);

                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex + vertoffset);
                o.uv = v.uv;
                return o;
            }

            float4 frag(Interpolators i) : SV_Target
            {
                return getripple(i.uv);
            }
            ENDCG
        }
    }
}