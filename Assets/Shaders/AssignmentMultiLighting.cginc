#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

sampler2D _RockAlbedo;
float4 _RockAlbedo_ST;
sampler2D _RockNormals;
sampler2D _RockHeight;
sampler2D _DiffuseIBL;
sampler2D _SpecularIBL;
float _NormalsIntensity;
float _HeightValue;
float4 _AmbientLight;
float _SpecularIntensity;
float4 _Color;
float _Gloss;

float2 dirtorectilinear(float3 d)
{
    // Returns between [PI, -PI] need to remap into [0, 1]
    float x = (atan2(d.z, d.x) / UNITY_PI) * 0.5 + 0.5;
    float y = d.y * 0.5 + 0.5;
    return float2(x, y);
}

struct MeshData
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
    float4 tangent : TANGENT; // xyz: tangent direction | w: tangent sign
};

struct Interpolators
{
    float4 vertex : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : TEXCOORD1;
    float3 tangent : TEXCOORD2;
    float3 bitangent : TEXCOORD3;
    float3 vertex_worldpos : TEXCOORD4;
    LIGHTING_COORDS(5, 6)
};

Interpolators vert(MeshData v)
{
    Interpolators o;
    float2 uv = TRANSFORM_TEX(v.uv, _RockAlbedo);
    // Remap from [0, 1] range to [-1, 1] range
    float t = tex2Dlod(_RockHeight, float4(uv, 0, 0)).x * 2.0 - 1.0;
    float3 offset = v.normal * t * _HeightValue;

    o.vertex = UnityObjectToClipPos(v.vertex + offset);
    o.uv = uv;
    o.normal = UnityObjectToWorldNormal(v.normal);
    o.tangent = UnityObjectToWorldDir(v.tangent.xyz);
    // Sign info of the tangent help us to correctly interpret the normal map in case the UVs are flipped
    // Likewise if the transform has negative scaling we also take it into account and handle it
    o.bitangent = cross(o.normal, o.tangent) * v.tangent.w * unity_WorldTransformParams.w;
    o.vertex_worldpos = mul(unity_ObjectToWorld, v.vertex);
    TRANSFER_VERTEX_TO_FRAGMENT(o);
    return o;
}

float4 frag(Interpolators i) : SV_Target
{
    float3 color = tex2D(_RockAlbedo, i.uv);
    float3 surfacecolor = color * _Color;

    float3 lightcolor = _LightColor0.xyz;

    // Diffuse lighting
    float3 tangentspacenormal = UnpackNormal(tex2D(_RockNormals, i.uv));
    float3 normal = normalize(lerp(float3(0, 0, 1), tangentspacenormal, _NormalsIntensity));
    float3x3 mtx = {
        i.tangent.x, i.bitangent.x, i.normal.x,
        i.tangent.y, i.bitangent.y, i.normal.y,
        i.tangent.z, i.bitangent.z, i.normal.z
    };
    float3 N = mul(mtx, normal);
    // float3 N = normalize(i.normal);
    float3 L = normalize(UnityWorldSpaceLightDir(i.vertex_worldpos));
    float attenuation = LIGHT_ATTENUATION(i);
    float lambert = saturate(dot(N, L));
    float3 diffuselight = lambert * attenuation * lightcolor;

    #ifdef IS_BASE_PASS
    #ifdef _AMBIENTLIGHT_ON
    diffuselight += _AmbientLight; // Adds the indirect diffuse lighting
    #else
    float3 diffuseibl = tex2Dlod(_DiffuseIBL, float4(dirtorectilinear(N), 0, 0));
    diffuselight += diffuseibl;
    #endif
    #endif

    // Specular exponent
    float specexp = exp2(_Gloss * 11.0) + 2;

    // Phong specular highlight
    float3 R = reflect(-L, N);
    float3 V = normalize(_WorldSpaceCameraPos - i.vertex_worldpos);
    float3 phongspecularlight = pow(saturate(dot(R, V)) * (lambert > 0.0F), specexp) * _Gloss * attenuation *
        lightcolor;

    // Blinn-Phong specular highlight
    float3 H = normalize(L + V);
    float3 blinnphongspecularlight = pow(saturate(dot(H, N)) * (lambert > 0.0F), specexp) * _Gloss * attenuation *
        lightcolor;

    #ifdef IS_BASE_PASS
    float fresnel = pow(1.0 - saturate(dot(V, N)), 5);
    float3 viewreflected = reflect(-V, N);
    float mip = (1.0 - _Gloss) * 6;
    float3 specularibl = tex2Dlod(_SpecularIBL, float4(dirtorectilinear(viewreflected), mip.xx));
    blinnphongspecularlight += (specularibl * _SpecularIntensity * fresnel);
    #endif

    float3 outcolor = diffuselight * surfacecolor + blinnphongspecularlight;

    return float4(outcolor, 1.0F);
}
