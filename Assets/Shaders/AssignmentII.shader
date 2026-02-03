Shader "Assignments/Two"
{
    Properties
    {
        _RockAlbedo ("Rock Albedo", 2D) = "white" {}
        [NoScaleOffset] _RockNormals ("Rock Normals", 2D) = "bump" {}
        [NoScaleOffset] _RockHeight ("Rock Height", 2D) = "gray" {}
        _HeightValue ("Height Value", Range(0.0, 0.4)) = 0
        _NormalsIntensity ("Normal Intensity", Range(0.0, 1.0)) = 0
        _AmbientLight ("Ambient Light", Color) = (1.0, 1.0, 1.0, 1.0)
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Gloss ("Gloss", Float) = 1.0
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }

        // Base pass
        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #define IS_BASE_PASS

            #include "AssignmentMultiLighting.cginc"
            ENDCG
        }

        // Add pass
        Pass
        {
            Tags
            {
                "LightMode" = "ForwardAdd"
            }

            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd

            #include "AssignmentMultiLighting.cginc"
            ENDCG
        }
    }
}