// Layer 7 - bloom-friendly additive glow. Writes above 1.0 so a URP Bloom pass has
// something over threshold to pick up; on a Screen Space - Overlay canvas (which is
// composited after post-processing and never receives Bloom) the wide soft falloff
// still reads as glow on its own.
Shader "UI/Mystic/7 Glow"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Tint      ("Tint",      Color)      = (1,1,1,1)
        _Speed     ("Speed",     Range(0,4)) = 1
        _Intensity ("Intensity", Range(0,4)) = 1.4
        _Opacity   ("Opacity",   Range(0,1)) = 0.85

        _GlowColor  ("Glow Color",  Color)          = (0.68, 0.32, 1.00, 1)
        _GlowCenter ("Glow Center", Range(0,1))     = 0.5
        // Wide values turn this layer into a full-plate colour wash rather than a glow.
        _GlowWidth  ("Glow Width",  Range(0.05,1))  = 0.22
        _Breathe    ("Breathe",     Range(0,1))     = 0.25
        _BreatheRate("Breathe Rate",Range(0,2))     = 0.35
        _Overdrive  ("HDR Overdrive", Range(1,4))   = 1.6

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
            Name "MYSTIC_GLOW"
        CGPROGRAM
            #pragma vertex MysticVert
            #pragma fragment frag
            #pragma target 3.0
            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP
            #include "MysticCommon.cginc"

            fixed4 _GlowColor;
            float _GlowCenter, _GlowWidth, _Breathe, _BreatheRate, _Overdrive;

            fixed4 frag (v2f IN) : SV_Target
            {
                float2 uv = IN.texcoord;

                float breathe = 1.0 + sin(_Time.y * _Speed * _BreatheRate * 6.2831853) * _Breathe;
                float w = max(_GlowWidth * breathe, 1e-3);

                float dy = (uv.y - _GlowCenter) / w;
                float band = exp(-dy * dy);

                // Soften the ends so the glow does not stop dead at the plate edge.
                float ends = smoothstep(0.0, 0.12, uv.x) * smoothstep(1.0, 0.88, uv.x);
                float g = band * ends;

                float3 rgb = _GlowColor.rgb * g * _Intensity * _Overdrive;

                fixed4 col = fixed4(rgb * _Tint.rgb,
                                    g * MysticMask(IN) * _Opacity * _Tint.a) * IN.color;
                MYSTIC_CLIP(col, IN)
                return col;
            }
        ENDCG
        }
    }
    Fallback Off
}
