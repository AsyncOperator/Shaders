Shader "Assignments/OneFreya"
{
    Properties
    {
        [NoScaleOffset] _HealthbarTex ("Healthbar Texture", 2D) = "white" {}
        _Health ("Health", Range(0.0, 1.0)) = 0.0
        _MinThreshold("Min Threshold", Range(0.0, 1.0)) = 0.0
        [Toggle] _ClipBlackPixels ("Clip Black Pixels", Integer) = 0
        _BorderOutlineThickness ("Border Outline Thickness", Range(0.05, 0.95)) = 0.0
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

            sampler2D _HealthbarTex;
            float _Health;
            float _MinThreshold;
            int _ClipBlackPixels;
            float _BorderOutlineThickness;

            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 scale : TEXCOORD1;
            };

            Interpolators vert(MeshData v)
            {
                float2 scale = float2
                (
                    length(unity_ObjectToWorld._m00_m10_m20),
                    length(unity_ObjectToWorld._m01_m11_m21)
                );

                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.scale = scale;
                return o;
            }

            half4 frag(Interpolators i) : SV_Target
            {
                float s = i.scale.x / i.scale.y;
                float2 coords = float2(i.uv.x * s, i.uv.y);
                float xclamped = clamp(coords.x, +0.5F, s - 0.5F);
                float2 referencepoint = float2(xclamped, 0.5F);
                float dist = distance(coords, referencepoint) * 2.0F;
                float signeddist = dist - 1.0F;
                clip(-signeddist);

                float bordersdf = signeddist + _BorderOutlineThickness;
                float pd = fwidth(bordersdf); // Screen space partial derivative
                float bordermask = 1 - saturate(bordersdf / pd);

                const float error_threshold = 0.001F;
                // Calculate border outline uv coverage percent on 0-1 range along x axis
                float borderuvcoveragepercent = _BorderOutlineThickness / (s * 2.0F) - error_threshold;
                float visibleuvxvalue = lerp(borderuvcoveragepercent, 1.0F - borderuvcoveragepercent, _Health);

                float healthmask = step(i.uv.x, visibleuvxvalue);
                bool clipblackbackground = all(bool2(bordermask, 1.0F - healthmask));
                clip(-clipblackbackground * _ClipBlackPixels);

                half4 color = tex2D(_HealthbarTex, float2(_Health, i.uv.y));

                // Generally branching in shader code is not good, it may cause some performance issue
                // but since this branching is deterministic, meaning that it is always gives the same result for every fragment
                // it is not that costly
                if (_Health < _MinThreshold)
                {
                    float pulsate = cos(_Time.y * 4.0F) * 0.4F + 1.0F;
                    color *= pulsate;
                }

                return color * bordermask * healthmask;
            }
            ENDCG
        }
    }
}