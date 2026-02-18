Shader "Unlit/Shader8"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MipValue ("MIP Value", Float) = 0
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

            float _MipValue;

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

            // Vertex shader can not figure out mip level automatically, so you can't use 'tex2D' function
            // but you can use 'tex2Dlod' function inside vertex shader
            Interpolators vert(MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            half4 frag(Interpolators i) : SV_Target
            {
                // We can sample the texture at given mip level if we want to
                half4 moss = tex2Dlod(_MainTex, float4(i.uv, _MipValue.xx));
                return moss;
            }
            ENDCG
        }
    }
}