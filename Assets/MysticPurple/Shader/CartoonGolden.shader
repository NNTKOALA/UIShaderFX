Shader "UI/FX/Cartoon Golden"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        [Header(Plate  set Opacity to 0 for no background)]
        _PlateTop    ("Plate Top",    Color) = (0.17, 0.18, 0.45, 1)
        _PlateBottom ("Plate Bottom", Color) = (0.09, 0.09, 0.27, 1)
        _PlateAlpha  ("Plate Opacity", Range(0,1)) = 0
        _CornerRadius ("Corner Radius (px)", Range(0,200)) = 24
        _EdgeSoft     ("Edge Softness (px)", Range(0.5,8)) = 1.5

        [Header(Rim)]
        _RimColor ("Rim Color", Color) = (0.48, 0.58, 1.0, 0)
        _RimWidth ("Rim Width (px)", Range(0,12)) = 0

        [Header(Colour)]
        _BandColor ("Band Colour",    Color) = (1.00, 0.45, 0.04, 1)
        _WaveColor ("Wave Highlight", Color) = (1.00, 0.82, 0.18, 1)
        _CoreColor ("Hot Core",       Color) = (1.00, 0.96, 0.78, 1)
        _WaveHighlight ("Highlight Amount",     Range(0,1))   = 0.85
        _WaveSharp     ("Highlight Sharpness",  Range(0.5,6)) = 2.0
        _WaveBoost     ("Highlight Brightness", Range(1,3))   = 1.4

        [Header(Band)]
        _Layers       ("Strand Count",     Range(2,10))       = 10
        _Thickness    ("Min Strand Width", Range(0.002,0.12)) = 0.035
        _ThicknessMul ("Strand Overlap",   Range(0.3,3))      = 0.7
        _Spread       ("Band Width",       Range(0,1))        = 0.65
        _Intensity    ("Glow Intensity",   Range(0,4))        = 1.4
        _Emission     ("Emission Boost (Bloom)", Range(1,8))  = 1.7

        [Header(Brush Shape  fan at top left to tip at bottom right)]
        _TipWidth      ("Tip Width",         Range(0.01,1))  = 0.18
        _ConvergePower ("Converge Curve",    Range(0.3,4))   = 1.5
        _TipNormalize  ("Tip Overlap Damp",  Range(0.05,1))  = 0.35
        _Slant         ("Descent (TL to BR)",Range(-1.5,1.5))= -0.62
        _Center        ("Vertical Center",   Range(0,1))     = 0.55
        _FadeIn        ("Fade In (left)",    Range(0,0.5))   = 0.06
        _FadeOut       ("Fade Out (right)",  Range(0,0.5))   = 0.05

        [Header(Wave)]
        _Amplitude ("Wave Amplitude", Range(0,0.6))  = 0.17
        _Frequency ("Wave Repeats",   Range(0.2,8))  = 2.6
        _Speed     ("Wave Speed",     Range(0,4))    = 2.2
        _WaveDamp  ("Wave Damp at Tip", Range(0,1))  = 0.30
        _Looseness ("Strand Looseness", Range(0,1))  = 0.45

        [Header(Haze)]
        _Haze      ("Band Haze",  Range(0,2))    = 0.7
        _HazeWidth ("Haze Width", Range(0.02,1)) = 0.26

        [Header(Cartoon Shaping)]
        _ToonSteps  ("Toon Bands",  Range(2,12)) = 5
        _ToonAmount ("Toon Amount", Range(0,1))  = 0.4

        [Header(Sparks)]
        _SparkColor    ("Spark Color", Color) = (1.0, 0.97, 0.92, 1)
        _SparkAmount   ("Spark Amount",   Range(0,3))    = 0.9
        _SparkSize     ("Spark Size",     Range(0.05,1)) = 0.4
        _SparkSpeed    ("Spark Speed",    Range(0,4))    = 1.4
        _SparkDensity  ("Spark Density",  Range(2,24))   = 8
        _SparkCoverage ("Spark Coverage", Range(0,1))    = 0.45

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
            Name "CARTOON_GOLDEN"
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
            fixed4 _Color;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;

            fixed4 _PlateTop, _PlateBottom, _RimColor;
            float _PlateAlpha, _CornerRadius, _EdgeSoft, _RimWidth;

            fixed4 _BandColor, _WaveColor, _CoreColor;
            float _WaveHighlight, _WaveSharp, _WaveBoost;

            float _Layers, _Thickness, _ThicknessMul, _Spread, _Intensity, _Emission;

            float _TipWidth, _ConvergePower, _TipNormalize, _Slant, _Center;
            float _FadeIn, _FadeOut;

            float _Amplitude, _Frequency, _Speed, _WaveDamp, _Looseness;
            float _Haze, _HazeWidth;
            float _ToonSteps, _ToonAmount;

            fixed4 _SparkColor;
            float _SparkAmount, _SparkSize, _SparkSpeed, _SparkDensity, _SparkCoverage;

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

            float Hash11(float n)
            {
                return frac(sin(n * 12.9898) * 43758.5453);
            }

            float2 Hash22(float2 p)
            {
                p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
                return frac(sin(p) * 43758.5453);
            }

            // Crest of the master wave, 0 in the troughs .. 1 on the peaks. Drives the
            // travelling highlight, so it must use the same term as MasterSpine or the
            // highlight would drift off the wave.
            float WaveCrest(float x, float t)
            {
                float w = sin(_Frequency * x * 6.2831853 - t);
                return pow(saturate(w * 0.5 + 0.5), _WaveSharp);
            }

            // One master wave every strand rides, so the whole thing reads as a single
            // band instead of unrelated filaments. Travels left->right over time and
            // settles down as it approaches the tip.
            float MasterSpine(float x, float t, float damp)
            {
                float w = _Amplitude * sin(_Frequency * x * 6.2831853 - t)
                        + _Amplitude * 0.35 * sin(_Frequency * 1.9 * x * 6.2831853 - t * 1.3 + 1.7);
                return _Center + w * damp + _Slant * (x - 0.5);
            }

            // Sparks drifting along the band, each looping inside its own cell so
            // nothing pops when the loop wraps.
            float Sparks(float2 uv, float t)
            {
                float2 g = uv * float2(_SparkDensity * 2.2, _SparkDensity);
                float2 cell = floor(g);
                float2 f = frac(g) - 0.5;

                float2 h = Hash22(cell);
                float alive = step(1.0 - _SparkCoverage, frac(h.x * 7.13 + h.y * 3.71));

                float life = frac(t * _SparkSpeed + h.x);
                float2 base = (h - 0.5) * 0.6;
                float2 pos = base + float2(0.9, -0.35) * (life - 0.5);
                float fade = sin(life * 3.14159265);

                float d = length((f - pos) * float2(1.0, 2.2));
                float s = pow(saturate(1.0 - d / max(_SparkSize, 1e-3)), 3.0);
                return s * alive * fade;
            }

            fixed4 frag (v2f IN) : SV_Target
            {
                float2 uv = IN.texcoord;

                // ---------- 1. Plate shape (mask only when Plate Opacity is 0) ----------
                float hasRect = step(1.0, IN.rect.x * IN.rect.y);
                float2 rect = lerp(float2(2.0, 2.0), IN.rect, hasRect);
                float2 halfSize = rect * 0.5;
                float2 p = (uv - 0.5) * rect;

                float sd = RoundedBoxSDF(p, halfSize, _CornerRadius);
                float shape = lerp(1.0, 1.0 - smoothstep(-_EdgeSoft, 0.0, sd), hasRect);

                float3 plate = lerp(_PlateBottom.rgb, _PlateTop.rgb, uv.y);

                // ---------- 2. Brush profile ----------
                // conv: 0 at the fanned base (left) -> 1 at the tip (right).
                float conv = pow(saturate(uv.x), _ConvergePower);
                float fan  = lerp(1.0, _TipWidth, conv);   // band half-width multiplier
                float damp = lerp(1.0, _WaveDamp, conv);   // wave settles toward the tip

                float env = smoothstep(0.0, max(_FadeIn, 1e-3), uv.x)
                          * smoothstep(1.0, 1.0 - max(_FadeOut, 1e-3), uv.x);

                // ---------- 3. Strands sharing the master spine ----------
                float t = _Time.y * _Speed;
                float spine = MasterSpine(uv.x, t, damp);

                float energy = 0.0;
                int count = max((int)round(_Layers), 2);

                for (int i = 0; i < 10; i++)
                {
                    if (i >= count) break;

                    float seed = Hash11((float)i + 1.0);

                    // Even placement across the band, plus a loose per-strand wobble that
                    // only exists near the fanned base (bristles tighten toward the tip).
                    float u = ((float)i + 0.5) / (float)count - 0.5;
                    float loose = (1.0 - conv) * _Looseness;
                    float wobble = loose * 0.5 * sin(_Frequency * 1.4 * uv.x * 6.2831853
                                                     - t * (0.7 + seed) + seed * 6.2831853);

                    float yc = spine + (u + wobble * 0.35) * _Spread * fan;

                    // Thickness tracks strand spacing so the band stays solid at both
                    // the fanned base and the converged tip, with an absolute floor so
                    // the tip is a band rather than a hairline.
                    float spacing = (_Spread * fan) / (float)count;
                    float th = max(spacing * _ThicknessMul, _Thickness) * (0.75 + seed * 0.5);
                    float d  = abs(uv.y - yc);

                    // Soft-shouldered falloff: 1 at the strand, long silky tail.
                    float g = th / (d + th);
                    energy += (pow(g, 3.0) * 0.85 + pow(g, 8.0) * 0.5) * (0.7 + seed * 0.5);
                }

                // Strands pile onto each other as they converge; damp so the tip does
                // not clip flat.
                energy *= lerp(1.0, _TipNormalize, conv) * env;

                // ---------- 4. Haze hugging the band ----------
                float hw = _HazeWidth * max(fan, 0.25);
                float dHaze = abs(uv.y - spine);
                float haze = pow(hw / (dHaze + hw), 2.0) * _Haze * env;

                // ---------- 5. Travelling wave highlight ----------
                // The whole band is one colour; the wave peaks lift it toward yellow and
                // brighten it, so the highlight rides along as the wave moves.
                float crest = WaveCrest(uv.x, t) * _WaveHighlight;
                float3 col = lerp(_BandColor.rgb, _WaveColor.rgb, crest);

                // ---------- 6. Tonemap + cartoon banding ----------
                float lum = 1.0 - exp(-energy * _Intensity * lerp(1.0, _WaveBoost, crest));
                float bands = max(_ToonSteps, 2.0);
                lum = saturate(lerp(lum, floor(lum * bands + 0.5) / bands, _ToonAmount));

                // Densest overlap burns out toward the core colour.
                col = lerp(col, _CoreColor.rgb, saturate(lum * 3.0 - 2.15));
                float3 hazeCol = lerp(_BandColor.rgb, _WaveColor.rgb, crest * 0.6);

                // ---------- 7. Sparks ----------
                float sparkMask = saturate(pow(saturate(haze), 1.6) * 1.5 + lum * 1.8);
                float spark = Sparks(uv, _Time.y) * sparkMask * _SparkAmount;

                // ---------- 8. Composite ----------
                float plateVis = _PlateAlpha * (1.0 - saturate((lum + haze * 0.6) * 0.85));
                float3 rgb = plate * plateVis;
                rgb += hazeCol * haze * 0.35;
                rgb += col * lum * _Emission;
                rgb += _SparkColor.rgb * spark;

                // ---------- 9. Rim light ----------
                float rim = shape * (1.0 - smoothstep(0.0, max(_RimWidth, 1e-3), -sd)) * hasRect;
                rgb = lerp(rgb, _RimColor.rgb, rim * _RimColor.a);

                float alpha = shape * saturate(_PlateAlpha + lum + haze * 0.5 + spark
                                               + rim * _RimColor.a);

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
