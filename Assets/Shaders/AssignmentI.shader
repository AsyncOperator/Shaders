Shader "Assignments/One"
{
    Properties
    {
        [Toggle] _USE_TEX ("Use Texture", Integer) = 0
        [NoScaleOffset] _HealthbarTex ("Healthbar Texture", 2D) = "white" {}
        _Health ("Health", Range(0.0, 1.0)) = 0.0
        _MinThreshold("Min Threshold", Range(0.0, 1.0)) = 0.0
        _MaxThreshold("Max Threshold", Range(0.0, 1.0)) = 0.0
        [Toggle] _ClipBlackPixels ("Clip Black Pixels", Integer) = 0
        _ColorStart ("Color Start", Color) = (1.0, 1.0, 1.0, 1.0)
        _ColorEnd ("Color End", Color) = (1.0, 1.0, 1.0, 1.0)
        _BorderOutlineThickness ("Border Outline Thickness", Range(0.0, 0.1)) = 0.0
    }

    CGINCLUDE
    #include "UnityCG.cginc"
    ENDCG

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }

        // First pass where we render healthbar
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature _USE_TEX_ON

            sampler2D _HealthbarTex;
            float _Health;
            float _MinThreshold;
            float _MaxThreshold;
            int _ClipBlackPixels;
            float4 _ColorStart;
            float4 _ColorEnd;

            float invlerp(float a, float b, float v)
            {
                return saturate((v - a) / (b - a));
            }

            float pulsate()
            {
                const float min_pulsate_speed = 0.2F;
                const float max_pulsate_speed = 2.55F;

                float pulsateactive = step(_Health, _MinThreshold);

                // We do not have to saturate this value, since the 'pulsateactive' acts as a guard to ensure we are in pulsate range
                float t = 1.0F - (_Health / _MinThreshold);
                float pulsatespeed = lerp(min_pulsate_speed, max_pulsate_speed, t);
                float time = 1.0F - abs(frac(_Time.y * pulsatespeed) * 2.0F - 1.0f);

                return pulsateactive * time;
            }

            half4 getcolor(float2 uv)
            {
                half4 color;

                #if _USE_TEX_ON
                uv.x = _Health;
                color = tex2D(_HealthbarTex, uv);
                #else
                float t = invlerp(_MinThreshold, _MaxThreshold, _Health);
                color = lerp(_ColorStart, _ColorEnd, t);
                #endif

                return color;
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
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            half4 frag(Interpolators i) : SV_Target
            {
                // It is best practice to clip the fragment as soon as possible to avoid doing some heavy operations
                // We could discard the pixel after calculating the color for the fragment which makes no sense
                float signvalue = sign(_Health - i.uv.x);
                clip(signvalue * _ClipBlackPixels);

                float mult = step(0.0F, signvalue);
                half4 color = getcolor(i.uv) * mult;

                return color - (color * pulsate());
            }
            ENDCG
        }

        // Second pass where we render border for healthbar
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float _BorderOutlineThickness;

            bool within(float min, float max, float v)
            {
                return min <= v && v <= max;
            }

            // Instead of calculating object scale on each vertex at vertex shader, we could define a property and pass the object scale data from C#
            // it might be more performant since we just need to update the property once before each render instead of calculating same data over and over again, which is unnecessary
            float2 getobjectscale()
            {
                float2 scale = float2
                (
                    length(unity_ObjectToWorld._m00_m10_m20), // X-axis scale
                    length(unity_ObjectToWorld._m01_m11_m21) // Y-axis scale
                );

                return scale;
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
                float2 scale : TEXCOORD1;
            };

            Interpolators vert(MeshData v)
            {
                float2 vertexsign = sign(v.vertex.xy);
                float2 scale = getobjectscale();
                float2 offset = vertexsign * (_BorderOutlineThickness / scale);

                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex + float3(offset, 0.0F));
                o.uv = v.uv;
                o.scale = scale;
                return o;
            }

            half4 frag(Interpolators i) : SV_Target
            {
                float xaxislength = i.scale.x + _BorderOutlineThickness * 2;
                float yaxislength = i.scale.y + _BorderOutlineThickness * 2;

                float thicknesspercentonxaxis = _BorderOutlineThickness / xaxislength;
                float thicknesspercentonyaxis = _BorderOutlineThickness / yaxislength;

                // If both the uv coordinate x and y is inside given range, then we discard that pixel
                bool xnotwithin = !within(thicknesspercentonxaxis, 1.0F - thicknesspercentonxaxis, i.uv.x);
                bool ynotwithin = !within(thicknesspercentonyaxis, 1.0F - thicknesspercentonyaxis, i.uv.y);
                bool render = any(bool2(xnotwithin, ynotwithin));
                clip(render - 1.0F);
                return 0;
            }
            ENDCG
        }
    }
}