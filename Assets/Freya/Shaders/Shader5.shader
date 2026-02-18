Shader "Unlit/Shader5"
{
    Properties
    {
        [Toggle] _VERT ("Use Vertex Shader Data", Integer) = 0
        _WaveAmp ("Wave Amplitude", Range(0.01, 0.2)) = 0.1
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

            #pragma shader_feature _VERT_ON

            #include "UnityCG.cginc"

            #define TAU UNITY_TWO_PI

            float _WaveAmp;

            float2 getwave(float2 uv)
            {
                return float2(sin((uv.y - _Time.x) * TAU * 7.0F), sin((uv.x - _Time.x) * TAU * 4.0F));
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
                float wave: TEXCOORD1;
            };

            Interpolators vert(MeshData v)
            {
                float2 wave = getwave(v.uv);
                float waveresult = wave.x * wave.y;
                float3 vertoffset = float3(0.0F, waveresult * _WaveAmp, 0.0F);

                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex + vertoffset);
                o.uv = v.uv;
                o.wave = waveresult;
                return o;
            }

            float4 frag(Interpolators i) : SV_Target
            {
                #if _VERT_ON
                    return i.wave;
                #else
                float2 wave = getwave(i.uv);
                return wave.x * wave.y;
                #endif
            }
            ENDCG
        }
    }
}