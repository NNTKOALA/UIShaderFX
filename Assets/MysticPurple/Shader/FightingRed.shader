Shader "UI/FX/Fighting Red"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        [Header(Plate  set Opacity to 0 for no background)]
        _PlateTop    ("Plate Top",    Color) = (0.18, 0.02, 0.04, 1)
        _PlateBottom ("Plate Bottom", Color) = (0.07, 0.01, 0.02, 1)
        _PlateAlpha  ("Plate Opacity", Range(0,1)) = 0
        _CornerRadius ("Corner Radius (px)", Range(0,200)) = 24
        _EdgeSoft     ("Edge Softness (px)", Range(0.5,8)) = 1.5

        [Header(Colour)]
        _RageDeep ("Dark Red",  Color) = (0.42, 0.01, 0.02, 1)
        _RageMid  ("Red",       Color) = (1.00, 0.10, 0.05, 1)
        _RageHot  ("Ember",     Color) = (1.00, 0.45, 0.12, 1)
        _CoreColor("White Hot", Color) = (1.00, 0.88, 0.78, 1)

        [Header(Misty Red Streaks)]
        // Soft gaussian streaks broken into separate patches by noise, so the trail
        // reads as drifting mist rather than clean speed lines.
        _StreakCount ("Streak Count",     Range(2,14))    = 2
        _StreakThick ("Streak Thickness", Range(0.005,0.2))= 0.06
        _Spread      ("Vertical Spread",  Range(0.1,1.2)) = 0.5
        _Center      ("Vertical Center",  Range(0,1))     = 0.5
        _Drift       ("Drift Speed",      Range(0,4))     = 0.85
        _Unevenness  ("Unevenness",       Range(0.5,12))  = 4.5
        _BreakUp     ("Break Up",         Range(0,1))     = 0.9
        _SmokeWarp   ("Smoke Warp",       Range(0,0.4))   = 0.16
        _Intensity   ("Glow Intensity",   Range(0,4))     = 0.8
        _Emission    ("Emission Boost",   Range(1,8))     = 1.6

        [Header(Fog)]
        _FogAmount ("Fog Amount",  Range(0,2))   = 0.3
        _FogScaleX ("Fog Scale X", Range(0.5,12))= 2.6
        _FogScaleY ("Fog Scale Y", Range(0.5,12))= 4.5
        _FogSpeed  ("Fog Speed",   Range(0,4))   = 0.55

        [Header(Spectrum Sweep)]
        _SweepSpeed ("Sweep Speed", Range(0,3))    = 0.3
        _SweepWidth ("Sweep Width", Range(0.05,1)) = 0.28
        _SweepBoost ("Sweep Boost", Range(0,4))    = 1.5

        [Header(Rage Sparks)]
        _SparkColor    ("Spark Color", Color) = (1.0, 0.55, 0.22, 1)
        _SparkAmount   ("Spark Amount",   Range(0,3))    = 1.0
        _SparkSize     ("Spark Size",     Range(0.05,1)) = 0.32
        _SparkSpeed    ("Spark Speed",    Range(0,6))    = 1.8
        _SparkDensity  ("Spark Density",  Range(2,24))   = 10
        _SparkCoverage ("Spark Coverage", Range(0,1))    = 0.4

        [Header(Edges)]
        _FadeIn  ("Fade In (left)",   Range(0,0.5)) = 0.06
        _FadeOut ("Fade Out (right)", Range(0,0.5)) = 0.06

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
            Name "FIGHTING_RED"
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

            fixed4 _RageDeep, _RageMid, _RageHot, _CoreColor;
            float _StreakCount, _StreakThick, _Spread, _Center;
            float _Drift, _Unevenness, _BreakUp, _SmokeWarp, _Intensity, _Emission;

            float _FogAmount, _FogScaleX, _FogScaleY, _FogSpeed;
            float _SweepSpeed, _SweepWidth, _SweepBoost;

            fixed4 _SparkColor;
            float _SparkAmount, _SparkSize, _SparkSpeed, _SparkDensity, _SparkCoverage;
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

            float Sparks(float2 uv, float t)
            {
                float2 g = uv * float2(_SparkDensity * 2.2, _SparkDensity);
                float2 cell = floor(g);
                float2 f = frac(g) - 0.5;

                float2 h = Hash22(cell);
                float alive = step(1.0 - _SparkCoverage, frac(h.x * 7.13 + h.y * 3.71));

                float life = frac(t * _SparkSpeed * 0.4 + h.x);
                float2 pos = (h - 0.5) * 0.6 + float2(1.0, 0.15) * (life - 0.5);
                float fade = sin(life * 3.14159265);

                float d = length((f - pos) * float2(1.0, 2.4));
                float s = pow(saturate(1.0 - d / max(_SparkSize, 1e-3)), 3.0);
                return s * alive * fade;
            }

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

                // Horizontal ends plus a vertical falloff, so the mist fades out near the
                // top and bottom instead of being sliced flat by the plate mask.
                float env = smoothstep(0.0, max(_FadeIn, 1e-3), uv.x)
                          * smoothstep(1.0, 1.0 - max(_FadeOut, 1e-3), uv.x)
                          * smoothstep(0.0, 0.22, uv.y) * smoothstep(1.0, 0.78, uv.y);

                // ---------- 2. Spectrum sweep ----------
                float sweepPos = frac(time * _SweepSpeed) * 1.4 - 0.2;
                float sx = (uv.x - sweepPos) / max(_SweepWidth, 1e-3);
                float sweep = exp(-sx * sx);

                // ---------- 3. Misty streaks ----------
                float energy = 0.0;
                int count = max((int)round(_StreakCount), 2);

                for (int i = 0; i < 14; i++)
                {
                    if (i >= count) break;

                    float seed = Hash11((float)i + 1.0);
                    float u = ((float)i + 0.5) / (float)count - 0.5;

                    // Noise-warped centre line. A straight band reads as a drawn line no
                    // matter how soft its edges are; bending the spine is what turns it
                    // into a drifting wisp of smoke.
                    float warp = (Fbm2(float2(uv.x * 1.7 - time * _Drift * 0.45,
                                              seed * 23.1)) - 0.5) * 2.0;
                    float y = _Center + u * _Spread + warp * _SmokeWarp;

                    // Gaussian profile: no hard edge anywhere.
                    float th = _StreakThick * (0.45 + seed * 1.3);
                    float dy = (uv.y - y) / max(th, 1e-4);
                    float prof = exp(-dy * dy);

                    // Noise along the streak cuts it into separate patches drifting right.
                    float along = Fbm2(float2(uv.x * _Unevenness - time * _Drift * (0.6 + seed),
                                              seed * 17.3));
                    along = lerp(along, smoothstep(0.35, 0.85, along), _BreakUp);

                    energy += prof * along * (0.5 + seed * 0.9);
                }

                // ---------- 4. Fog layer ----------
                float bandMask = exp(-pow((uv.y - _Center) / max(_Spread * 0.7, 1e-3), 2.0));
                float fog = Fbm2(float2(uv.x * _FogScaleX - time * _FogSpeed,
                                        uv.y * _FogScaleY + time * 0.15));
                fog = smoothstep(0.35, 0.95, fog) * bandMask * _FogAmount;

                energy = (energy + fog) * env * (1.0 + sweep * _SweepBoost);

                // ---------- 5. Colour ----------
                float lum = saturate(1.0 - exp(-energy * _Intensity));

                float3 col = _RageDeep.rgb;
                col = lerp(col, _RageMid.rgb, saturate(lum * 3.2));
                col = lerp(col, _RageHot.rgb, saturate(lum * 2.4 - 1.1));
                col = lerp(col, _CoreColor.rgb, saturate(lum * 4.0 - 3.5));

                float spark = Sparks(uv, time) * saturate(lum * 1.8) * env * _SparkAmount;

                float3 rgb = plate * _PlateAlpha * (1.0 - saturate(lum * 0.85));
                rgb += col * lum * _Emission;
                rgb += _SparkColor.rgb * spark;

                float alpha = shape * saturate(_PlateAlpha + lum + spark);
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
