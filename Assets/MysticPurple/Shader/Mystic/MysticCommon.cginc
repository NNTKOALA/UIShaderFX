// Shared plumbing for the layered "Mystic Purple" effect.
//
// Every layer is its own Image + material, so this file carries the parts they all
// need: the UI vertex layout, the rounded-rect mask, and cheap value noise.
//
// The mask is recomputed per layer instead of using a UI Mask component. A Mask costs
// an extra draw call and a stencil pass per masked child; this SDF is ~10 ALU and
// folds into the layer's own fragment shader, which is the cheaper trade on mobile.
#ifndef MYSTIC_COMMON_INCLUDED
#define MYSTIC_COMMON_INCLUDED

#include "UnityCG.cginc"
#include "UnityUI.cginc"

struct appdata_t
{
    float4 vertex   : POSITION;
    float4 color    : COLOR;
    float2 texcoord : TEXCOORD0;
    float2 rect     : TEXCOORD1;   // rect size in px, fed by UIRectSizeFeeder
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    float4 vertex   : SV_POSITION;
    fixed4 color    : COLOR;
    float2 texcoord : TEXCOORD0;
    float2 rect     : TEXCOORD1;
    float4 worldPos : TEXCOORD2;
    UNITY_VERTEX_OUTPUT_STEREO
};

sampler2D _MainTex;
float4 _MainTex_ST;
fixed4 _TextureSampleAdd;
float4 _ClipRect;

// Contract shared by every layer, so one controller can drive them all uniformly.
fixed4 _Tint;
float _Speed, _Intensity, _Opacity;
float _CornerRadius, _EdgeSoft;

v2f MysticVert(appdata_t v)
{
    v2f o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    o.worldPos = v.vertex;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
    o.rect = v.rect;
    o.color = v.color;
    return o;
}

float RoundedBoxSDF(float2 pxFromCenter, float2 halfSize, float radius)
{
    float r = min(radius, min(halfSize.x, halfSize.y));
    float2 q = abs(pxFromCenter) - (halfSize - r);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// Coverage of the rounded plate. Falls back to 1 when no rect has been fed, so a
// layer still renders if the feeder is missing rather than vanishing silently.
float MysticMask(v2f IN)
{
    float hasRect = step(1.0, IN.rect.x * IN.rect.y);
    float2 rect = lerp(float2(2.0, 2.0), IN.rect, hasRect);
    float2 p = (IN.texcoord - 0.5) * rect;
    float sd = RoundedBoxSDF(p, rect * 0.5, _CornerRadius);
    return lerp(1.0, 1.0 - smoothstep(-_EdgeSoft, 0.0, sd), hasRect);
}

float Hash11(float n) { return frac(sin(n * 12.9898) * 43758.5453); }
float Hash21(float2 p) { return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453); }

float2 Hash22(float2 p)
{
    p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
    return frac(sin(p) * 43758.5453);
}

float Noise2(float2 p)
{
    float2 i = floor(p), f = frac(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = Hash21(i);
    float b = Hash21(i + float2(1, 0));
    float c = Hash21(i + float2(0, 1));
    float d = Hash21(i + float2(1, 1));
    return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
}

// Two and three octave variants. Layers pick the cheapest one that still reads.
float Fbm2(float2 p)
{
    return Noise2(p) * 0.65 + Noise2(p * 2.07 + 11.3) * 0.35;
}

float Fbm3(float2 p)
{
    return Noise2(p) * 0.52 + Noise2(p * 2.03 + 11.3) * 0.31 + Noise2(p * 4.11 + 27.7) * 0.17;
}

// UI rect clipping and alpha clip, identical in every layer.
#ifdef UNITY_UI_CLIP_RECT
    #define _MYSTIC_CLIP_RECT(col, IN) col.a *= UnityGet2DClipping(IN.worldPos.xy, _ClipRect);
#else
    #define _MYSTIC_CLIP_RECT(col, IN)
#endif

#ifdef UNITY_UI_ALPHACLIP
    #define _MYSTIC_ALPHACLIP(col) clip(col.a - 0.001);
#else
    #define _MYSTIC_ALPHACLIP(col)
#endif

#define MYSTIC_CLIP(col, IN) _MYSTIC_CLIP_RECT(col, IN) _MYSTIC_ALPHACLIP(col)

#endif // MYSTIC_COMMON_INCLUDED
