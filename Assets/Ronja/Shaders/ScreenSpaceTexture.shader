Shader "Ronja/ScreenSpaceTexture"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }

        Pass
        {
            CGPROGRAM
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;
            float4 _MainTex_ST;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 position : SV_POSITION;
                float4 screen_position : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;
                float4 clipPos = UnityObjectToClipPos(v.vertex);
                o.position = clipPos;
                o.screen_position = ComputeScreenPos(clipPos);
                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                float aspect = _ScreenParams.x / _ScreenParams.y;
                // This division is to counteract the perspective correction the GPU automatically performs on interpolators
                float2 texCoord = i.screen_position.xy / i.screen_position.w;
                texCoord.x *= aspect;
                fixed4 col = tex2D(_MainTex, TRANSFORM_TEX(texCoord, _MainTex));
                return col;
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}