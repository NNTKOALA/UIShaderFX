Shader "UI/FX/Mystic Purple"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        [Header(Plate  set Opacity to 0 for no background)]
        _PlateTop    ("Plate Top",    Color) = (0.10, 0.03, 0.22, 1)
        _PlateBottom ("Plate Bottom", Color) = (0.04, 0.01, 0.10, 1)
        _PlateAlpha  ("Plate Opacity", Range(0,1)) = 0
        _CornerRadius ("Corner Radius (px)", Range(0,200)) = 24
        _EdgeSoft     ("Edge Softness (px)", Range(0.5,8)) = 1.5

        [Header(Colour)]
        _RimDeep   ("Deep Violet",  Color) = (0.28, 0.04, 0.55, 1)
        _RimMid    ("Purple",       Color) = (0.60, 0.16, 0.95, 1)
        _RimHot    ("Lavender",     Color) = (0.82, 0.55, 1.00, 1)
        _CrestCore ("Crest White",  Color) = (1.00, 0.98, 1.00, 1)

        [Header(Wave Crests  vertical lines swelling like surf)]
        _CrestCount ("Crest Count",   Range(2,24))       = 14
        _CrestWidth ("Crest Width",   Range(0.001,0.03)) = 0.004
        _RimWidthF  ("Purple Rim",    Range(1,12))       = 4.0
        _Spread     ("Crest Spread",  Range(0.1,1))      = 0.92
        _Center     ("Horizontal Center",Range(0,1))     = 0.5
        _Amplitude  ("Wave Amplitude",Range(0,0.3))      = 0.06
        _Frequency  ("Wave Repeats",  Range(0.2,8))      = 0.75
        _Speed      ("Wave Speed",    Range(0,4))        = 0.75
        _Chop       ("Wave Chop",     Range(0,1))        = 0.22
        _Intensity  ("Glow Intensity",Range(0,4))        = 1.15
        _Emission   ("Emission Boost",Range(1,8))        = 1.5

        [Header(Purple Fog Sweep)]
        // A broad purple fog bank drifting left to right; inside it the rim walks along
        // the violet -> lavender range, which is what reads as a spectrum.
        _SweepSpeed ("Sweep Speed", Range(0,3))      = 0.22
        _SweepWidth ("Sweep Width", Range(0.05,1))   = 0.5
        _SweepBoost ("Sweep Boost", Range(0,4))      = 1.8
        _SweepHue   ("Sweep Hue Shift", Range(0,1))  = 0.85
        _SweepFog   ("Sweep Fog Break", Range(0,1))  = 0.7
        _FogScale   ("Fog Scale",   Range(0.5,10))   = 2.4
        _FogSpeed   ("Fog Speed",   Range(0,3))      = 0.35

        [Header(Glowing Particles)]
        _MoteColor    ("Mote Color", Color) = (0.92, 0.75, 1.00, 1)
        _MoteAmount   ("Mote Amount",   Range(0,3))    = 1.0
        _MoteSize     ("Mote Size",     Range(0.02,1)) = 0.26
        _MoteDensity  ("Mote Density",  Range(2,30))   = 12
        _MoteSpeed    ("Mote Speed",    Range(0,4))    = 0.6
        _MoteCoverage ("Mote Coverage", Range(0,1))    = 0.4

        [Header(Edges)]
        _FadeIn  ("Fade In (left)",   Range(0,0.5)) = 0.05
        _FadeOut ("Fade Out (right)", Range(0,0.5)) = 0.05

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
            Name "MYSTIC_PURPLE"
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

            fixed4 _RimDeep, _RimMid, _RimHot, _CrestCore;
            float _CrestCount, _CrestWidth, _RimWidthF, _Spread, _Center;
            float _Amplitude, _Frequency, _Speed, _Chop, _Intensity, _Emission;

            float _SweepSpeed, _SweepWidth, _SweepBoost, _SweepHue;
            float _SweepFog, _FogScale, _FogSpeed;

            fixed4 _MoteColor;
            float _MoteAmount, _MoteSize, _MoteDensity, _MoteSpeed, _MoteCoverage;
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

            float Fbm2(float2 p)
            {
                return Noise2(p) * 0.65 + Noise2(p * 2.07 + 11.3) * 0.35;
            }

            float Motes(float2 uv, float t)
            {
                float2 g = uv * float2(_MoteDensity * 2.2, _MoteDensity);
                float2 cell = floor(g);
                float2 f = frac(g) - 0.5;

                float2 h = Hash22(cell);
                float alive = step(1.0 - _MoteCoverage, frac(h.x * 7.13 + h.y * 3.71));

                float life = frac(t * _MoteSpeed * 0.4 + h.x);
                float2 pos = (h - 0.5) * 0.6 + float2(0.8, 0.2) * (life - 0.5);
                float fade = sin(life * 3.14159265);

                float d = length(f - pos);
                float s = pow(saturate(1.0 - d / max(_MoteSize, 1e-3)), 3.0);
                return s * alive * fade;
            }

            fixed4 frag (v2f IN) : SV_Target
            {
                float2 uv = IN.texcoord;
                float time = _Time.y;
                float t = time * _Speed;

                // ---------- 1. Plate shape ----------
                float hasRect = step(1.0, IN.rect.x * IN.rect.y);
                float2 rect = lerp(float2(2.0, 2.0), IN.rect, hasRect);
                float2 halfSize = rect * 0.5;
                float2 pxc = (uv - 0.5) * rect;
                float sd = RoundedBoxSDF(pxc, halfSize, _CornerRadius);
                float shape = lerp(1.0, 1.0 - smoothstep(-_EdgeSoft, 0.0, sd), hasRect);
                float3 plate = lerp(_PlateBottom.rgb, _PlateTop.rgb, uv.y);

                // Horizontal ends plus a vertical falloff, so the crests fade out near
                // the top and bottom instead of being sliced flat by the plate mask.
                float env = smoothstep(0.0, max(_FadeIn, 1e-3), uv.x)
                          * smoothstep(1.0, 1.0 - max(_FadeOut, 1e-3), uv.x)
                          * smoothstep(0.0, 0.20, uv.y) * smoothstep(1.0, 0.80, uv.y);

                // ---------- 2. Purple fog sweep ----------
                // A wide gaussian bank, then broken up by noise so its silhouette is
                // ragged like fog instead of a clean travelling band.
                float sweepPos = frac(time * _SweepSpeed) * 1.6 - 0.3;
                float sx = (uv.x - sweepPos) / max(_SweepWidth, 1e-3);
                float sweep = exp(-sx * sx);

                float fogN = Fbm2(float2(uv.x * _FogScale - time * _FogSpeed,
                                         uv.y * _FogScale * 0.7 + time * _FogSpeed * 0.3));
                sweep *= lerp(1.0, saturate(fogN * 1.8), _SweepFog);

                // ---------- 3. Wave crests ----------
                // Each crest is a travelling sine plus a slower counter-moving one, which
                // gives the interference pattern that reads as swell seen from above.
                float core = 0.0;   // tight white centre of each crest
                float rim  = 0.0;   // wide purple halo around it
                int count = max((int)round(_CrestCount), 2);

                for (int i = 0; i < 14; i++)
                {
                    if (i >= count) break;

                    float seed = Hash11((float)i + 1.0);
                    float u = ((float)i + 0.5) / (float)count - 0.5;

                    // Vertical crests: the line runs top to bottom and its x position
                    // swells with uv.y, so the swell travels down the line like surf.
                    float f1 = _Frequency * (0.8 + seed * 0.5);
                    float x = _Center + u * _Spread
                            + _Amplitude * sin(f1 * uv.y * 6.2831853 - t * (0.8 + seed * 0.6)
                                               + seed * 6.2831853)
                            + _Amplitude * _Chop * sin(f1 * 2.3 * uv.y * 6.2831853
                                                       + t * 0.7 + seed * 11.0);

                    float th = _CrestWidth * (0.7 + seed * 0.7);
                    float d = abs(uv.x - x);

                    float gc = th / (d + th);
                    core += pow(gc, 6.0) * (0.7 + seed * 0.5);

                    float rw = th * _RimWidthF;
                    float gr = rw / (d + rw);
                    rim += pow(gr, 2.5) * (0.5 + seed * 0.6);
                }

                // The sweep lifts the crests it passes over.
                float boost = 1.0 + sweep * _SweepBoost;
                core *= env * boost;
                rim  *= env * boost;

                // ---------- 4. Colour ----------
                float rimLum  = saturate(1.0 - exp(-rim * _Intensity));
                float coreLum = saturate(1.0 - exp(-core * _Intensity * 1.4));

                // Rim walks violet -> lavender; the sweep pushes it further along that
                // range so the travelling band reads as a shift in wavelength.
                float rimT = saturate(rimLum * 1.6 + sweep * _SweepHue);
                float3 rimCol = lerp(_RimDeep.rgb, _RimMid.rgb, saturate(rimT * 2.0));
                rimCol = lerp(rimCol, _RimHot.rgb, saturate(rimT * 2.0 - 1.0));

                float3 rgb = plate * _PlateAlpha * (1.0 - saturate((rimLum + coreLum) * 0.8));
                rgb += rimCol * rimLum * _Emission;
                // White crest drawn on top of its own purple rim.
                rgb += _CrestCore.rgb * coreLum * _Emission * 0.9;

                float mote = Motes(uv, time) * saturate(rimLum * 1.8) * env * _MoteAmount;
                rgb += _MoteColor.rgb * mote;

                float alpha = shape * saturate(_PlateAlpha + rimLum + coreLum + mote);
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
