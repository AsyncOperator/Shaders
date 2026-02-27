Shader "Ronja/CustomLightingSurface"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _RampTex("Ramp Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }

        CGPROGRAM
        // Custom lighting model, and enable shadows on all light types
        #pragma surface surf Custom fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _RampTex;
        fixed4 _Color;

        struct Input
        {
            float2 uv_MainTex;
        };

        float4 LightingCustom(SurfaceOutput s, float3 lightDir, float atten)
        {
            float NdotL = dot(s.Normal, lightDir);
            float NdotL01 = NdotL * 0.5 + 0.5;
            float3 rampColor = tex2D(_RampTex, float2(NdotL01, 0.5)).rgb;

            float4 col;
            col.rgb = rampColor * atten * s.Albedo * _LightColor0.rgb;
            col.a = s.Alpha;

            return col;
        }

        void surf(Input IN, inout SurfaceOutput o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}