Shader "Ronja/ScreenSpaceTextureSurface"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        [HDR] _Emission ("Emission", Color) = (1,1,1,1)
        _Smoothness ("Smoothness", Range(0,1)) = 0
        _Metallic ("Metallic", Range(0,1)) = 0
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        float4 _MainTex_ST;
        fixed4 _Color;
        half3 _Emission;
        half _Smoothness;
        half _Metallic;

        struct Input
        {
            float4 screenPos;
        };

        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            float aspect = _ScreenParams.x / _ScreenParams.y;
            float2 texCoord = IN.screenPos.xy / IN.screenPos.w;
            texCoord.x *= aspect;

            fixed4 c = tex2D(_MainTex, TRANSFORM_TEX(texCoord, _MainTex)) * _Color;
            o.Albedo = c.rgb;
            o.Alpha = c.a;
            o.Emission = _Emission;
            o.Smoothness = _Smoothness;
            o.Metallic = _Metallic;
        }
        ENDCG
    }
    FallBack "Diffuse"
}