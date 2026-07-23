// Layer 4 - wave fronts bowed toward the right, marching left to right.
//
// Each front is a parabola that bulges rightward at mid height, so the arc reads as a
// wave travelling outward rather than a straight vertical line. Drawn as two passes:
// a tight white core and a wide purple rim around it.
Shader "UI/Mystic/4 Ribbons"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Tint      ("Tint",      Color)      = (1,1,1,1)
        _Speed     ("Speed",     Range(0,4)) = 1
        _Intensity ("Intensity", Range(0,4)) = 1
        _Opacity   ("Opacity",   Range(0,1)) = 1

        _RimColor  ("Rim Color (purple)", Color) = (0.62, 0.20, 1.00, 1)
        _CoreColor ("Core Color (white)", Color) = (0.98, 0.94, 1.00, 1)

        _WaveCount ("Wave Count",  Range(1,10))       = 5
        _CoreWidth ("Core Width",  Range(0.0005,0.02))= 0.0035
        _RimWidth  ("Rim Width",   Range(1,16))       = 6.0
        _Bow       ("Bow Right",   Range(0,0.6))      = 0.22
        _Wobble    ("Wobble",      Range(0,0.2))      = 0.02
        _WobbleFreq("Wobble Freq", Range(0.5,6))      = 1.5
        _Zigzag    ("Zigzag",      Range(0,0.2))      = 0.06
        _ZigMin    ("Zigzag Min Kinks", Range(1,8))   = 2
        _ZigMax    ("Zigzag Max Kinks", Range(1,8))   = 5
        _ZigDrift  ("Zigzag Drift",Range(0,1))        = 0.18
        _ZigRound  ("Corner Round",Range(0,1))        = 0.45
        _ZigVary   ("Per Line Variation", Range(0,1)) = 0.8
        _ScrollRate("Scroll Rate", Range(0,2))        = 0.16
        _EndFade   ("End Fade",    Range(0.02,0.4))   = 0.14

        _CornerRadius ("Corner Radius (px)", Range(0,200)) = 24
        _EdgeSoft     ("Edge Softness (px)", Range(0.5,8)) = 1.5

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
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"
               "PreviewType"="Plane" "CanUseSpriteAtlas"="True" }

        Stencil { Ref [_Stencil] Comp [_StencilComp] Pass [_StencilOp]
                  ReadMask [_StencilReadMask] WriteMask [_StencilWriteMask] }

        Cull Off  Lighting Off  ZWrite Off  ZTest [unity_GUIZTestMode]
        Blend SrcAlpha One
        ColorMask [_ColorMask]

        Pass
        {
            Name "MYSTIC_RIBBONS"
        CGPROGRAM
            #pragma vertex MysticVert
            #pragma fragment frag
            #pragma target 3.0
            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP
            #include "MysticCommon.cginc"

            fixed4 _RimColor, _CoreColor;
            float _WaveCount, _CoreWidth, _RimWidth, _Bow;
            float _Wobble, _WobbleFreq, _ScrollRate, _EndFade;
            float _Zigzag, _ZigMin, _ZigMax, _ZigDrift, _ZigRound, _ZigVary;

            // Triangle wave in -1..1: sharp corners, unlike sin which can only ever
            // produce smooth bends.
            float TriWave(float x)
            {
                return abs(frac(x) * 2.0 - 1.0) * 2.0 - 1.0;
            }

            // Blending the triangle toward a sine of the same period rounds the corners
            // while keeping the kinked rhythm. round = 0 is a hard zigzag, 1 a pure wave.
            float RoundedTri(float x, float round)
            {
                return lerp(TriWave(x), sin(x * 6.2831853), round);
            }

            fixed4 frag (v2f IN) : SV_Target
            {
                float2 uv = IN.texcoord;
                float t = _Time.y * _Speed * _ScrollRate;

                // -1 at the bottom edge, +1 at the top.
                float ny = (uv.y - 0.5) * 2.0;

                // Parabola: zero at both edges, maximum at mid height. Adding it to the
                // front's x position is what bows the arc toward the right.
                float bow = _Bow * (1.0 - ny * ny);

                float core = 0.0;
                float rim = 0.0;
                int count = max((int)round(_WaveCount), 1);

                for (int i = 0; i < 10; i++)
                {
                    if (i >= count) break;

                    float seed = Hash11((float)i + 1.0);

                    // Evenly spaced along the travel, each wrapping independently.
                    float pos = frac((float)i / (float)count + t) * 1.3 - 0.15;

                    float wob = _Wobble * sin(ny * 3.14159265 * _WobbleFreq
                                              + _Time.y * _Speed * (0.8 + seed)
                                              + seed * 6.2831853);

                    // Each front gets its own segment count, amplitude and drift
                    // direction, otherwise all the kinks line up and the fronts read as
                    // one repeated stamp.
                    float seedB = Hash11((float)i + 17.3);

                    // Whole number of kinks drawn from [min, max], so every front lands on
                    // a clean count instead of a fractional segment cut off mid-kink.
                    float lo = min(_ZigMin, _ZigMax);
                    float hi = max(_ZigMin, _ZigMax);
                    float segs = floor(lerp(lo, hi + 0.999, seedB));
                    float amp = _Zigzag * lerp(1.0, 0.5 + seed * 1.2, _ZigVary);
                    float dir = (seedB > 0.5) ? 1.0 : -1.0;

                    float zig = RoundedTri(ny * segs + seed * 3.7
                                           + _Time.y * _Speed * _ZigDrift * dir,
                                           _ZigRound) * amp;

                    float xc = pos + bow + wob + zig;
                    float d = abs(uv.x - xc);

                    // Fade each front in and out at the ends of its travel, otherwise
                    // the wrap pops a hard line onto the plate edge.
                    float f = smoothstep(0.0, _EndFade, pos) * smoothstep(1.0, 1.0 - _EndFade, pos);

                    float th = _CoreWidth * (0.7 + seed * 0.6);
                    float gc = th / (d + th);
                    core += pow(gc, 6.0) * f;

                    float rw = th * _RimWidth;
                    float gr = rw / (d + rw);
                    rim += pow(gr, 2.5) * f * (0.6 + seed * 0.5);
                }

                // Soften the top and bottom so the arcs are not sliced by the plate edge.
                float vEnv = smoothstep(0.0, 0.12, uv.y) * smoothstep(1.0, 0.88, uv.y);
                core *= vEnv;
                rim *= vEnv;

                float rimLum  = saturate(1.0 - exp(-rim * _Intensity * 1.4));
                float coreLum = saturate(1.0 - exp(-core * _Intensity * 2.0));

                float3 rgb = _RimColor.rgb * rimLum + _CoreColor.rgb * coreLum;

                float a = saturate(rimLum + coreLum) * MysticMask(IN) * _Opacity * _Tint.a;
                fixed4 col = fixed4(rgb * _Tint.rgb, a) * IN.color;
                MYSTIC_CLIP(col, IN)
                return col;
            }
        ENDCG
        }
    }
    Fallback Off
}
