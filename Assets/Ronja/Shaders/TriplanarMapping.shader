Shader "Ronja/TriplanarMapping"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Sharpness ("Blend Sharpness", Range(1.0, 64.0)) = 1.0
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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Sharpness;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float3 worldPosition : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 uvFront = TRANSFORM_TEX(i.worldPosition.xy, _MainTex);
                float2 uvSide = TRANSFORM_TEX(i.worldPosition.yz, _MainTex);
                float2 uvTop = TRANSFORM_TEX(i.worldPosition.xz, _MainTex);

                float3 absNormal = abs(normalize(i.normal));
                absNormal = pow(absNormal, _Sharpness);
                absNormal = absNormal / (absNormal.x + absNormal.y + absNormal.z);

                float4 sampleFront = tex2D(_MainTex, uvFront) * absNormal.z;
                float4 sampleSide = tex2D(_MainTex, uvSide) * absNormal.x;
                float4 sampleTop = tex2D(_MainTex, uvTop) * absNormal.y;

                float4 col = sampleFront + sampleSide + sampleTop;
                return col;
            }
            ENDCG
        }
    }
}