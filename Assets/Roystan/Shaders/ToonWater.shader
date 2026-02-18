Shader "Roystan/Toon/Water"
{
    Properties
    {
        _SurfaceNoise("Surface Noise", 2D) = "white" {}
        _SurfaceNoiseCutoff("Surface Noise Cutoff", Range(0.0, 1.0)) = 0.5
        _SurfaceNoiseScroll("Surface Noise Scroll Amount", Vector) = (0.03, 0.03, 0, 0)

        _SurfaceDistortion("Surface Distortion", 2D) = "white" {}
        _SurfaceDistortionAmount("Surface Distortion Amount", Range(0, 1)) = 0.27

        _FoamColor("Foam Color", Color) = (1,1,1,1)
        _FoamMinDistance("Foam Minimum Distance", Float) = 0.04
        _FoamMaxDistance("Foam Maximum Distance", Float) = 0.4

        _DepthGradientShallow("Depth Gradient Shallow", Color) = (0.325, 0.807, 0.971, 0.725)
        _DepthGradientDeep("Depth Gradient Deep", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance("Depth Maximum Distance", Float) = 1
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
        }
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define SMOOTHSTEP_AA 0.01

            sampler2D _SurfaceNoise;
            float4 _SurfaceNoise_ST;
            float _SurfaceNoiseCutoff;
            float2 _SurfaceNoiseScroll;
            sampler2D _SurfaceDistortion;
            float4 _SurfaceDistortion_ST;
            float _SurfaceDistortionAmount;

            float4 _FoamColor;
            float _FoamMinDistance;
            float _FoamMaxDistance;
            float4 _DepthGradientShallow;
            float4 _DepthGradientDeep;
            float _DepthMaxDistance;

            sampler2D _CameraDepthTexture;
            sampler2D _CameraNormalsTexture;

            float4 AlphaBlend(float4 top, float4 bottom)
            {
                float3 color = (top.rgb * top.a) + (bottom.rgb * (1.0 - top.a));
                float alpha = top.a + bottom.a * (1.0 - top.a);

                return float4(color, alpha);
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
                float2 noise_uv : TEXCOORD0;
                float2 distortion_uv : TEXCOORD2;
                float4 screen_position : TEXCOORD3;
                float3 view_normal : NORMAL;
            };

            Interpolators vert(MeshData v)
            {
                Interpolators o;

                float4 clipPosition = UnityObjectToClipPos(v.vertex);
                o.vertex = clipPosition;
                o.noise_uv = TRANSFORM_TEX(v.uv, _SurfaceNoise);
                o.distortion_uv = TRANSFORM_TEX(v.uv, _SurfaceDistortion);
                o.screen_position = ComputeScreenPos(clipPosition);
                o.view_normal = COMPUTE_VIEW_NORMAL;

                return o;
            }

            float4 frag(Interpolators i) : SV_Target
            {
                float existingDepth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screen_position)).x;
                float existingDepthLinear = LinearEyeDepth(existingDepth01);
                float depthDifference = existingDepthLinear - i.screen_position.w;
                float waterDepthDifference01 = saturate(depthDifference / _DepthMaxDistance);
                float4 waterColor = lerp(_DepthGradientShallow, _DepthGradientDeep, waterDepthDifference01);

                // Remap getting -1 to 1
                float2 distortSample = (tex2D(_SurfaceDistortion, i.distortion_uv).xy * 2.0 - 1.0) *
                    _SurfaceDistortionAmount;

                float2 scrolledNoiseUV = i.noise_uv + distortSample + _Time.y * _SurfaceNoiseScroll;
                float surfaceNoiseSample = tex2D(_SurfaceNoise, scrolledNoiseUV).r;

                float3 existingNormal = tex2Dproj(_CameraNormalsTexture, UNITY_PROJ_COORD(i.screen_position));
                float normalDot = saturate(dot(existingNormal, i.view_normal));

                float foamDistance = lerp(_FoamMaxDistance, _FoamMinDistance, normalDot);

                float foamDepthDifference01 = saturate(depthDifference / foamDistance);
                float surfaceNoiseCutoff = foamDepthDifference01 * _SurfaceNoiseCutoff;
                // float surfaceNoise = step(surfaceNoiseCutoff, surfaceNoiseSample);
                float surfaceNoise = smoothstep(surfaceNoiseCutoff - SMOOTHSTEP_AA, surfaceNoiseCutoff + SMOOTHSTEP_AA,
                                                surfaceNoiseSample);
                float4 surfaceNoiseColor = float4(_FoamColor.rgb, _FoamColor.a * surfaceNoise);

                return AlphaBlend(surfaceNoiseColor, waterColor);
            }
            ENDCG
        }
    }
}