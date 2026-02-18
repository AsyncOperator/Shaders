Shader "Roystan/Toon"
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white" {}
        _Color("Color", Color) = (0.5, 0.65, 1, 1)
        [HDR] _AmbientColor("Ambient Color", Color) = (0.4,0.4,0.4,1)
        [HDR] _SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1)
        _Glossiness("Glossiness", Float) = 32
        [HDR] _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimAmount("Rim Amount", Range(0, 1)) = 0.716
        _RimThreshold("Rim Threshold", Range(0, 1)) = 0.1

    }
    SubShader
    {
        Pass
        {
            // Setup our pass to use Forward rendering, and only receive
            // data on the main directional light and ambient light.
            Tags
            {
                "LightMode" = "ForwardBase"
                "PassFlags" = "OnlyDirectional"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // Compile multiple versions of this shader depending on lighting settings.
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float4 _AmbientColor;

            float4 _SpecularColor;
            float _Glossiness;

            float4 _RimColor;
            float _RimAmount;
            float _RimThreshold;

            struct MeshData
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 uv : TEXCOORD0;
            };

            struct Interpolators
            {
                float4 pos : SV_POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float3 viewDir : TEXCOORD1;
                // Macro found in Autolight.cginc. Declares a vector4
				// into the TEXCOORD2 semantic with varying precision 
				// depending on platform target.
                SHADOW_COORDS(2)
            };

            Interpolators vert(MeshData v)
            {
                Interpolators o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                // Defined in Autolight.cginc. Assigns the above shadow coordinate
				// by transforming the vertex from world space to shadow-map space.
                TRANSFER_SHADOW(o);
                return o;
            }

            float4 frag(Interpolators i) : SV_Target
            {
                float3 N = normalize(i.normal);
                float3 L = _WorldSpaceLightPos0;
                float NdotL = dot(N, L);

                // Samples the shadow map, returning a value in the 0...1 range,
				// where 0 is in the shadow, and 1 is not.
                float shadow = SHADOW_ATTENUATION(i);

                float lightIntensity = smoothstep(0, 0.01, NdotL * shadow);
                float4 light = lightIntensity * _LightColor0;

                float3 viewDir = normalize(i.viewDir);
                float3 H = normalize(L + viewDir);
                float NdotH = dot(N, H);
                float specularIntensity = pow(NdotH * lightIntensity, _Glossiness * _Glossiness);
                float specularIntensitySmooth = smoothstep(0.005, 0.01, specularIntensity);
                float4 specular = specularIntensitySmooth * _SpecularColor;

                float rimDot = 1 - dot(viewDir, N);
                float rimIntensity = rimDot * pow(NdotL, _RimThreshold);
                rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);
                float4 rim = rimIntensity * _RimColor;

                float4 sample = tex2D(_MainTex, i.uv);

                return _Color * sample * (_AmbientColor + light + specular + rim);
            }
            ENDCG
        }
        // Shadow casting support
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}