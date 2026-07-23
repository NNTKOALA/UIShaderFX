// Layer 3 - purple mist drifting left to right.
//
// Same construction as the Fighting Red mist: soft gaussian bands whose centre lines
// are bent by noise, then cut into separate patches by a second noise field scrolling
// along x. Feature sizes are 1.5x that layer's, so the wisps read larger and slower.
//
// A gaussian profile over a noise-warped spine is what makes this read as vapour; a
// straight band still reads as a drawn line however soft its edges are.
Shader "UI/Mystic/3 Smoke"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Tint      ("Tint",      Color)      = (1,1,1,1)
        _Speed     ("Speed",     Range(0,4)) = 1
        _Intensity ("Intensity", Range(0,4)) = 1
        _Opacity   ("Opacity",   Range(0,1)) = 0.8

        _SmokeColor ("Smoke Color", Color) = (0.42, 0.12, 0.72, 1)
        _EdgeColor  ("Highlight",   Color) = (0.80, 0.55, 1.00, 1)

        [Header(Mist Bands)]
        _BandCount  ("Band Count",     Range(1,8))      = 3
        _BandThick  ("Band Thickness", Range(0.02,0.5)) = 0.09
        _Spread     ("Vertical Spread",Range(0.1,1.2))  = 0.8
        _Center     ("Vertical Center",Range(0,1))      = 0.5
        _Drift      ("Drift Speed",    Range(0,4))      = 0.6
        _Unevenness ("Unevenness",     Range(0.5,12))   = 3.0
        _BreakUp    ("Break Up",       Range(0,1))      = 0.85
        _SmokeWarp  ("Smoke Warp",     Range(0,0.4))    = 0.14

        [Header(Fog Sheet)]
        // The broad sheet is what reads as a solid purple background when turned up.
        // Keep it low: the mist bands above carry the layer.
        _FogAmount ("Fog Amount",  Range(0,2))    = 0.1
        _FogScaleX ("Fog Scale X", Range(0.5,12)) = 1.75
        _FogScaleY ("Fog Scale Y", Range(0.5,12)) = 3.0
        _FogSpeed  ("Fog Speed",   Range(0,4))    = 0.4

        [Header(Repeating Bank)]
        _BankSpeed ("Bank Speed", Range(0,2))    = 0.22
        _BankWidth ("Bank Width", Range(0.05,1)) = 0.34
        _BankBoost ("Bank Boost", Range(0,2))    = 0.7

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
            Name "MYSTIC_SMOKE"
        CGPROGRAM
            #pragma vertex MysticVert
            #pragma fragment frag
            #pragma target 3.0
            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP
            #include "MysticCommon.cginc"

            fixed4 _SmokeColor, _EdgeColor;
            float _BandCount, _BandThick, _Spread, _Center;
            float _Drift, _Unevenness, _BreakUp, _SmokeWarp;
            float _FogAmount, _FogScaleX, _FogScaleY, _FogSpeed;
            float _BankSpeed, _BankWidth, _BankBoost;

            fixed4 frag (v2f IN) : SV_Target
            {
                float2 uv = IN.texcoord;
                float time = _Time.y * _Speed;

                // Fade on all four sides so the mist is never sliced by the plate mask.
                float env = smoothstep(0.0, 0.05, uv.x) * smoothstep(1.0, 0.95, uv.x)
                          * smoothstep(0.0, 0.14, uv.y) * smoothstep(1.0, 0.86, uv.y);

                // ---------- Mist bands ----------
                float mist = 0.0;
                int count = max((int)round(_BandCount), 1);

                for (int i = 0; i < 8; i++)
                {
                    if (i >= count) break;

                    float seed = Hash11((float)i + 1.0);
                    float u = ((float)i + 0.5) / (float)count - 0.5;

                    // Noise-warped spine: this is what turns a band into a wisp.
                    float warp = (Fbm2(float2(uv.x * 1.2 - time * _Drift * 0.4,
                                              seed * 23.1)) - 0.5) * 2.0;
                    float y = _Center + u * _Spread + warp * _SmokeWarp;

                    float th = _BandThick * (0.45 + seed * 1.3);
                    float dy = (uv.y - y) / max(th, 1e-4);
                    float prof = exp(-dy * dy);

                    // Second noise field cuts the band into patches drifting right.
                    float along = Fbm2(float2(uv.x * _Unevenness - time * _Drift * (0.6 + seed),
                                              seed * 17.3));
                    along = lerp(along, smoothstep(0.35, 0.85, along), _BreakUp);

                    mist += prof * along * (0.5 + seed * 0.9);
                }

                // ---------- Broad fog sheet ----------
                float bandMask = exp(-pow((uv.y - _Center) / max(_Spread * 0.7, 1e-3), 2.0));
                float fog = Fbm2(float2(uv.x * _FogScaleX - time * _FogSpeed,
                                        uv.y * _FogScaleY + time * 0.1));
                fog = smoothstep(0.35, 0.95, fog) * bandMask * _FogAmount;

                // ---------- Repeating bank sweep ----------
                // Travels past both edges before wrapping, so it enters and leaves cleanly.
                float bankPos = frac(time * _BankSpeed) * 1.4 - 0.2;
                float bx = (uv.x - bankPos) / max(_BankWidth, 1e-3);
                float bank = exp(-bx * bx);

                float density = (mist + fog) * env * (1.0 + bank * _BankBoost);

                float lum = saturate(1.0 - exp(-density * _Intensity * 1.3));

                float3 rgb = lerp(_SmokeColor.rgb, _EdgeColor.rgb, saturate(lum * 1.6 - 0.6));
                rgb *= lum;

                float a = lum * MysticMask(IN) * _Opacity * _Tint.a;
                fixed4 col = fixed4(rgb * _Tint.rgb, a) * IN.color;
                MYSTIC_CLIP(col, IN)
                return col;
            }
        ENDCG
        }
    }
    Fallback Off
}
