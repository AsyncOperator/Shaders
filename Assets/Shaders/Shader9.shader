Shader "Unlit/Shader9"
{
    Properties
    {
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Gloss ("Gloss", Float) = 1.0
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
            #include "Lighting.cginc"

            float4 _Color;
            float _Gloss;

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
                float3 viewdir : TEXCOORD2;
            };

            Interpolators vert(MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.viewdir = WorldSpaceViewDir(v.vertex);
                return o;
            }

            float4 frag(Interpolators i) : SV_Target
            {
                float3 lightcolor = _LightColor0.xyz;

                // Diffuse lighting
                float3 N = normalize(i.normal);
                float3 L = _WorldSpaceLightPos0.xyz; // Directional light direction negated
                float lambert = saturate(dot(N, L));
                float3 diffuselight = lambert * lightcolor;

                // Phong specular highlight
                float3 R = reflect(-L, N);
                float3 V = normalize(i.viewdir);
                float3 phongspecularlight = pow(saturate(dot(R, V)), _Gloss) * (lambert > 0.0F) * lightcolor;

                // Blinn-Phong specular highlight
                float3 H = normalize((L + V));
                float blinnphongspecularlight = pow(saturate(dot(H, N)), _Gloss) * (lambert > 0.0F) * lightcolor;

                float fresnel = 1.0F - dot(V, N);
                // return float4(fresnel.xxx, 1.0F);

                return float4(diffuselight * _Color + blinnphongspecularlight, 1.0F);
            }
            ENDCG
        }
    }
}