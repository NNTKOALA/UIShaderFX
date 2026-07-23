Shader "UI/FX/Cyber SciFi"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        [Header(Plate  set Opacity to 0 for no background)]
        _PlateTop    ("Plate Top",    Color) = (0.03, 0.09, 0.20, 1)
        _PlateBottom ("Plate Bottom", Color) = (0.01, 0.03, 0.10, 1)
        _PlateAlpha  ("Plate Opacity", Range(0,1)) = 0
        _CornerRadius ("Corner Radius (px)", Range(0,200)) = 24
        _EdgeSoft     ("Edge Softness (px)", Range(0.5,8)) = 1.5

        [Header(Colour)]
        _LineDeep ("Deep Blue", Color) = (0.00, 0.20, 0.60, 1)
        _LineMid  ("Azure",     Color) = (0.12, 0.62, 1.00, 1)
        _LineHot  ("Cyan",      Color) = (0.50, 0.92, 1.00, 1)
        _CoreColor("White",     Color) = (1.00, 1.00, 1.00, 1)

        [Header(Thin Blue Lines)]
        _LineCount     ("Line Count",     Range(2,24))       = 14
        _LineThickness ("Line Thickness", Range(0.001,0.04)) = 0.005
        _LineSpread    ("Line Spread",    Range(0.1,1))      = 0.8
        _LineCenter    ("Line Center",    Range(0,1))        = 0.5
        _LineWave      ("Line Wave",      Range(0,0.1))      = 0.018
        _LineDrift     ("Line Drift",     Range(0,3))        = 0.6
        _LineFlicker   ("Line Flicker",   Range(0,1))        = 0.45
        _Intensity     ("Glow Intensity", Range(0,4))        = 1.15
        _Emission      ("Emission Boost", Range(1,8))        = 1.6

        [Header(Headlight Sweep)]
        // A blown-out white hotspot travelling left to right, like a headlight
        // pointed straight into the lens.
        _SweepSpeed   ("Sweep Speed",     Range(0,3))     = 0.32
        _SweepWidth   ("Sweep Width",     Range(0.02,0.8))= 0.16
        _SweepPower   ("Sweep Power",     Range(0,8))     = 5.0
        _FlareLength  ("Flare Length",    Range(0.05,2))  = 0.22
        _FlareHeight  ("Flare Height",    Range(0.02,1))  = 0.10
        _FlareAmount  ("Flare Amount",    Range(0,4))     = 0.9
        _StreakAmount ("Vertical Streak", Range(0,3))     = 0.5

        [Header(Scan Lines)]
        _ScanCount    ("Scan Line Count", Range(2,300)) = 90
        _ScanStrength ("Scan Strength",   Range(0,1))   = 0.35
        _ScanSpeed    ("Scan Speed",      Range(-8,8))  = -1.2

        [Header(Digital Noise)]
        _GlitchAmount ("Glitch Amount", Range(0,1))  = 0.35
        _GlitchRows   ("Glitch Rows",   Range(2,80)) = 24
        _GlitchSpeed  ("Glitch Rate",   Range(0,30)) = 10
        _GlitchShift  ("Glitch Shift",  Range(0,0.5))= 0.10
        _NoiseAmount  ("Static Noise",  Range(0,1))  = 0.16

        [Header(Edges)]
        _FadeIn  ("Fade In (left)",   Range(0,0.5)) = 0.04
        _FadeOut ("Fade Out (right)", Range(0,0.5)) = 0.04

        // --- UI plumbing ---
        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
        _ColorMask ("Color Mask", Float) = 15
        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
            "CanUseSpriteAtlas" = "True"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            Name "CYBER_SCIFI"
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #include "UnityCG.cginc"
            #include "UnityUI.cginc"
            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                float2 rect     : TEXCOORD1;
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
            fixed4 _Color;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;

            fixed4 _PlateTop, _PlateBottom;
            float _PlateAlpha, _CornerRadius, _EdgeSoft;

            fixed4 _LineDeep, _LineMid, _LineHot, _CoreColor;
            float _LineCount, _LineThickness, _LineSpread, _LineCenter;
            float _LineWave, _LineDrift, _LineFlicker, _Intensity, _Emission;

            float _SweepSpeed, _SweepWidth, _SweepPower;
            float _FlareLength, _FlareHeight, _FlareAmount, _StreakAmount;

            float _ScanCount, _ScanStrength, _ScanSpeed;
            float _GlitchAmount, _GlitchRows, _GlitchSpeed, _GlitchShift, _NoiseAmount;
            float _FadeIn, _FadeOut;

            v2f vert (appdata_t v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.worldPos = v.vertex;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.rect = v.rect;
                o.color = v.color * _Color;
                return o;
            }

            float RoundedBoxSDF(float2 pxFromCenter, float2 halfSize, float radius)
            {
                float r = min(radius, min(halfSize.x, halfSize.y));
                float2 q = abs(pxFromCenter) - (halfSize - r);
                return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
            }

            float Hash11(float n) { return frac(sin(n * 12.9898) * 43758.5453); }
            float Hash21(float2 p) { return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453); }

            fixed4 frag (v2f IN) : SV_Target
            {
                float2 uv = IN.texcoord;
                float time = _Time.y;

                // ---------- 1. Plate shape ----------
                float hasRect = step(1.0, IN.rect.x * IN.rect.y);
                float2 rect = lerp(float2(2.0, 2.0), IN.rect, hasRect);
                float2 halfSize = rect * 0.5;
                float2 pxc = (uv - 0.5) * rect;
                float sd = RoundedBoxSDF(pxc, halfSize, _CornerRadius);
                float shape = lerp(1.0, 1.0 - smoothstep(-_EdgeSoft, 0.0, sd), hasRect);
                float3 plate = lerp(_PlateBottom.rgb, _PlateTop.rgb, uv.y);

                float env = smoothstep(0.0, max(_FadeIn, 1e-3), uv.x)
                          * smoothstep(1.0, 1.0 - max(_FadeOut, 1e-3), uv.x);

                // ---------- 2. Glitch: shift whole rows in discrete time steps ----------
                float rowId = floor(uv.y * _GlitchRows);
                float frameId = floor(time * _GlitchSpeed);
                float2 gk = float2(rowId, frameId);
                float live = step(1.0 - _GlitchAmount, Hash21(gk + 3.7));
                float2 guv = float2(uv.x + (Hash21(gk) - 0.5) * _GlitchShift * live, uv.y);

                // ---------- 3. Headlight sweep ----------
                // Travels a little beyond both edges so it enters and leaves cleanly.
                float sweepPos = frac(time * _SweepSpeed) * 1.4 - 0.2;
                float sx = (uv.x - sweepPos) / max(_SweepWidth, 1e-3);
                float sweep = exp(-sx * sx);

                // ---------- 4. Thin blue lines ----------
                float energy = 0.0;
                int count = max((int)round(_LineCount), 2);

                for (int i = 0; i < 24; i++)
                {
                    if (i >= count) break;

                    float seed = Hash11((float)i + 1.0);
                    float u = ((float)i + 0.5) / (float)count - 0.5;

                    // Lines drift slowly and breathe, so the stack never looks static.
                    float drift = sin(time * _LineDrift * (0.4 + seed) + seed * 6.2831853);
                    float y = _LineCenter + u * _LineSpread + drift * _LineWave;

                    float th = _LineThickness * (0.6 + seed * 0.9);
                    float d = abs(guv.y - y);
                    float g = th / (d + th);
                    // Not named "line": that is a reserved HLSL primitive-type keyword.
                    // High power keeps the tails short so 14 stacked streaks stay
                    // readable as separate bands instead of merging into a slab.
                    float streak = pow(g, 5.0) * (0.5 + seed * 0.9);

                    // Digital flicker along the streak's length.
                    float flick = 0.5 + 0.5 * sin(guv.x * (18.0 + seed * 40.0)
                                                  - time * (3.0 + seed * 6.0) + seed * 12.0);
                    streak *= lerp(1.0, flick, _LineFlicker);

                    // The sweep blows the streaks out where it passes.
                    streak *= 1.0 + sweep * _SweepPower;

                    energy += streak;
                }
                energy *= env;

                // ---------- 5. Lens flare around the hotspot ----------
                // Wide horizontal bar plus a short vertical spike: the two axes are what
                // read as a light source aimed into the camera.
                float fx = (uv.x - sweepPos) / max(_FlareLength, 1e-3);
                float fy = (uv.y - _LineCenter) / max(_FlareHeight, 1e-3);
                float bar = exp(-fx * fx) * exp(-fy * fy) * _FlareAmount;

                float vx = (uv.x - sweepPos) / max(_SweepWidth * 0.55, 1e-3);
                float vy = (uv.y - _LineCenter) / 0.85;
                float spike = exp(-vx * vx) * exp(-vy * vy) * _StreakAmount;

                float flare = (bar + spike) * env;

                // ---------- 6. Scan lines + static ----------
                float scan = 0.5 + 0.5 * sin((uv.y * _ScanCount + time * _ScanSpeed) * 6.2831853);
                energy *= lerp(1.0, scan, _ScanStrength);

                float stat = Hash21(floor(uv * float2(160.0, 90.0)) + frameId * 17.0);
                energy *= lerp(1.0, stat, _NoiseAmount);

                // ---------- 7. Colour ----------
                float lum = saturate(1.0 - exp(-(energy + flare) * _Intensity));

                float3 col = _LineDeep.rgb;
                col = lerp(col, _LineMid.rgb, saturate(lum * 2.4));
                col = lerp(col, _LineHot.rgb, saturate(lum * 2.2 - 0.8));
                // Whiteness comes from the sweep, not from brightness alone, so the
                // hotspot reads as a separate white patch riding over the blue.
                col = lerp(col, _CoreColor.rgb, saturate(sweep * 1.3 * lum + lum * 3.0 - 2.6));

                float3 rgb = plate * _PlateAlpha * (1.0 - saturate(lum * 0.85));
                rgb += col * lum * _Emission;

                float alpha = shape * saturate(_PlateAlpha + lum);
                fixed4 col4 = fixed4(rgb, alpha) * IN.color;

                #ifdef UNITY_UI_CLIP_RECT
                col4.a *= UnityGet2DClipping(IN.worldPos.xy, _ClipRect);
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip(col4.a - 0.001);
                #endif

                return col4;
            }
        ENDCG
        }
    }
    Fallback "UI/Default"
}
