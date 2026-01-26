Shader "Unlit/Shader7"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MossTex ("Moss Texture", 2D) = "white" {}
        _RockTex ("Rock Texture", 2D) = "white" {}
        _PatternTex ("Pattern Texture", 2D) = "white" {}
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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _MossTex;
            sampler2D _RockTex;
            sampler2D _PatternTex;

            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 vertex_worldpos : TEXCOORD1;
            };

            Interpolators vert(MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                // You use this function when you want to modify the scale/translate values of the texture, otherwise it's unnecessary
                o.uv = v.uv; // TRANSFORM_TEX(v.uv, _MainTex);
                o.vertex_worldpos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            half4 frag(Interpolators i) : SV_Target
            {
                float2 topdownprojection = i.vertex_worldpos.xz;

                half4 moss = tex2D(_MossTex, topdownprojection);
                half4 rock = tex2D(_RockTex, topdownprojection);
                float pattern = tex2D(_PatternTex, i.uv);

                return lerp(moss, rock, pattern);
            }
            ENDCG
        }
    }
}