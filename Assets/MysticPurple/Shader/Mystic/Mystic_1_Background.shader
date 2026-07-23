// Layer 1 - dark background gradient. Alpha blended: this is the only opaque layer,
// everything above it is additive.
Shader "UI/Mystic/1 Background"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Tint      ("Tint",      Color)      = (1,1,1,1)
        _Speed     ("Speed",     Range(0,4)) = 0
        _Intensity ("Intensity", Range(0,4)) = 1
        _Opacity   ("Opacity",   Range(0,1)) = 1

        _TopColor    ("Top Color",    Color) = (0.12, 0.04, 0.26, 1)
        _BottomColor ("Bottom Color", Color) = (0.03, 0.01, 0.08, 1)
        _VignettePow ("Vignette",     Range(0,4)) = 1.1

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
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            Name "MYSTIC_BACKGROUND"
        CGPROGRAM
            #pragma vertex MysticVert
            #pragma fragment frag
            #pragma target 3.0
            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP
            #include "MysticCommon.cginc"

            fixed4 _TopColor, _BottomColor;
            float _VignettePow;

            fixed4 frag (v2f IN) : SV_Target
            {
                float2 uv = IN.texcoord;

                float3 rgb = lerp(_BottomColor.rgb, _TopColor.rgb, uv.y);

                // Darken toward the ends so the plate sits into the UI rather than
                // reading as a hard filled box.
                float vig = 1.0 - pow(abs(uv.x - 0.5) * 2.0, 2.0) * 0.55 * _VignettePow;
                rgb *= saturate(vig) * _Intensity;

                fixed4 col = fixed4(rgb * _Tint.rgb, MysticMask(IN) * _Opacity * _Tint.a);
                col *= IN.color;
                MYSTIC_CLIP(col, IN)
                return col;
            }
        ENDCG
        }
    }
    Fallback Off
}
