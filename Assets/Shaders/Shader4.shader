Shader "Unlit/Shader4"
{
    Properties
    {
        [Toggle] _ApplyOffset ("Apply Offset", Integer) = 0
        _StepThreshold ("Step Threshold", Range(0.0, 1.0)) = 0.0
        _ColorA ("Color A", Color) = (1.0, 1.0, 1.0, 1.0)
        _ColorB ("Color B", Color) = (1.0, 1.0, 1.0, 1.0)
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }

        Pass
        {
            Cull Off // Renders both side of the object back and front
            // Cull Back // This is default cull behaviour means that just render front side of the object and cull the back side of it
            ZWrite Off // Disable write onto depth buffer ~ Depth buffer
            ZTest LEqual // This is default ZTest behaviour ~ Depth testing
            Blend One One // Additive blending
            // Blend DstColor Zero // Multiplicative/Multiply blending
            // Blend SrcAlpha OneMinusSrcAlpha // Alpha blending

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            int _ApplyOffset;
            float _StepThreshold;
            float4 _ColorA;
            float4 _ColorB;

            float easeoutcbc(float x)
            {
                return 1.0F - pow(1.0F - x, 3);
            }

            float easeincbc(float x)
            {
                return x * x * x;
            }

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
                float time = _Time.y * 0.1F;
                float offset = _ApplyOffset * cos((i.uv.x) * UNITY_TWO_PI * 8) * 0.02F;

                // t = sin((i.uv.x + offset + time) * UNITY_TWO_PI * 6 - UNITY_HALF_PI) * 0.5F + 0.5F;
                float t = step(cos((i.uv.y + offset - time) * UNITY_TWO_PI * 4 - UNITY_PI) * 0.5F + 0.5F,
                               _StepThreshold);

                t *= easeincbc(1.0F - i.uv.y);

                // Converting world normal direction to object space normal direction
                // Rather than doing this way, we could also populate the Interpolators normal field with directly MeshData normal (which is already in object space)
                float3 localnormal = normalize(mul((float3x3)unity_WorldToObject, i.normal));
                // Calculating the dot product of local space normal and up vector
                float absdot = abs(dot(localnormal, float3(0.0F, 1.0F, 0.0F)));

                // What step function is doing is that { return 0.99F >= absdot }
                // If the absdot value is almost near equal to 1.0F which happens when the localnormal is almost same as up or -up direction
                // then the step function returns false (0) otherwise returns true (1)
                // and by multiplying this value with the t value, then decide whether we should output some color in this fragment or not
                float4 color = lerp(_ColorA, _ColorB, i.uv.y);
                return color * t * step(absdot, 0.99F);
            }
            ENDCG
        }
    }
}