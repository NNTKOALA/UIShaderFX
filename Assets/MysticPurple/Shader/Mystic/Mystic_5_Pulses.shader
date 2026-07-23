// Layer 5 - localized energy pulses. Each site has its own period and phase derived
// from a hash, so they fire at unrelated times rather than blinking together.
Shader "UI/Mystic/5 Pulses"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Tint      ("Tint",      Color)      = (1,1,1,1)
        _Speed     ("Speed",     Range(0,4)) = 1
        _Intensity ("Intensity", Range(0,4)) = 1
        _Opacity   ("Opacity",   Range(0,1)) = 1

        _PulseColor ("Pulse Color", Color) = (0.80, 0.45, 1.00, 1)
        _PulseCount ("Pulse Count", Range(1,8))       = 5
        _PulseSize  ("Pulse Size",  Range(0.02,0.5))  = 0.16
        _PulseRate  ("Pulse Rate",  Range(0.05,2))    = 0.35
        _RingSharp  ("Ring Sharpness", Range(1,8))    = 3.0
        _SiteDrift  ("Site Drift",  Range(0,0.5))     = 0.12

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
            Name "MYSTIC_PULSES"
        CGPROGRAM
            #pragma vertex MysticVert
            #pragma fragment frag
            #pragma target 3.0
            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP
            #include "MysticCommon.cginc"

            fixed4 _PulseColor;
            float _PulseCount, _PulseSize, _PulseRate, _RingSharp, _SiteDrift;

            fixed4 frag (v2f IN) : SV_Target
            {
                float2 uv = IN.texcoord;

                // Aspect-correct so pulses stay round on a wide plate.
                float hasRect = step(1.0, IN.rect.x * IN.rect.y);
                float aspect = lerp(1.0, IN.rect.x / max(IN.rect.y, 1e-3), hasRect);

                float glow = 0.0;
                int count = max((int)round(_PulseCount), 1);

                for (int i = 0; i < 8; i++)
                {
                    if (i >= count) break;

                    float2 h = Hash22(float2((float)i + 1.0, 7.3));

                    // Independent period and phase per site: this is what keeps the
                    // layer from reading as one synchronised blink.
                    float period = 0.6 + h.x * 1.8;
                    float phase = h.y;
                    float k = frac(_Time.y * _Speed * _PulseRate / period + phase);

                    // Site wanders slightly so repeats do not land in the same spot.
                    float2 site = float2(0.08 + h.x * 0.84, 0.2 + h.y * 0.6);
                    site += float2(sin(_Time.y * 0.21 + h.x * 6.0),
                                   cos(_Time.y * 0.17 + h.y * 6.0)) * _SiteDrift * 0.2;

                    float2 d = float2((uv.x - site.x) * aspect, uv.y - site.y);
                    float r = length(d) / max(_PulseSize, 1e-3);

                    // Expanding ring that fades over its life.
                    float radius = k * 1.4;
                    float ring = exp(-pow(abs(r - radius) * _RingSharp, 2.0));
                    float life = sin(k * 3.14159265);

                    glow += ring * life * (0.6 + h.x * 0.7);
                }

                float lum = saturate(1.0 - exp(-glow * _Intensity * 1.5));
                float3 rgb = _PulseColor.rgb * lum;

                fixed4 col = fixed4(rgb * _Tint.rgb,
                                    lum * MysticMask(IN) * _Opacity * _Tint.a) * IN.color;
                MYSTIC_CLIP(col, IN)
                return col;
            }
        ENDCG
        }
    }
    Fallback Off
}
