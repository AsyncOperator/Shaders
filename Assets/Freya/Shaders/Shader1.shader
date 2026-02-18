Shader "Unlit/Shader1"
{
    Properties
    {
        _Value ("Value", Float) = 1.0
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Scale ("UV Scale", Float) = 1.0
        _Offset ("UV Offset", Vector) = (0.0, 0.0, 0.0, 0.0)
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

            // We have to define properties as variables in order to access in our shader code
            float _Value;
            float4 _Color;
            float _Scale;
            float2 _Offset;

            // Automatically filled out by Unity
            struct MeshData // Per-vertex mesh data
            {
                float4 vertex : POSITION; // Local space vertex's position
                float2 uv : TEXCOORD0; // This semantics 'TEXCOORD' specifically refers to uv channel
                float3 normal : NORMAL; // Local space vertex's normal direction
                float4 color : COLOR; // Vertex color
            };

            // Data passed from vertex shader to fragment shader
            // this will interpolate/blend across triangle
            struct Interpolators
            {
                float4 vertex : SV_POSITION; // Clip space position
                float2 uv : TEXCOORD0;
                // 'TEXCOORD' semantics here is not related with uv channel at all, it's just a data stream
                float3 normal : TEXCOORD1;
            };

            Interpolators vert(MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex); // Converts local space position to clip space position
                o.uv = (v.uv + _Offset) * _Scale;
                // All of them are the same things
                // o.normal = UnityObjectToWorldNormal(v.normal);
                // o.normal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                o.normal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));
                // ~All of them are the same things

                return o;
            }

            // float, highest precision (32 bit)
            // half, moderate precision (16 bit)
            // fixed, lowest precision and most platform does not support it

            // float4 -> half4 -> fixed4 (Vector4)
            // float4x4 -> half4x4 -> fixed4x4 (Matrix4x4)

            float4 frag(Interpolators i) : SV_Target
            {
                return float4(i.uv, 0.0F, 1.0F);
                // return float4(i.normal, 1.0F);
                // return _Color;
                // return _Value;
            }
            ENDCG
        }
    }
}