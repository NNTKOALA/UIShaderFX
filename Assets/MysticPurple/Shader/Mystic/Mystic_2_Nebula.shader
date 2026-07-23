// Layer 2 - slow-moving nebula. Two FBM fields scrolling at different rates and
// directions; the parallax between them is what gives depth without a texture.
Shader "UI/Mystic/2 Nebula"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Tint      ("Tint",      Color)      = (1,1,1,1)
        _Speed     ("Speed",     Range(0,4)) = 1
        _Intensity ("Intensity", Range(0,4)) = 1
        _Opacity   ("Opacity",   Range(0,1)) = 0.75

        _NebulaA  ("Nebula Deep", Color) = (0.20, 0.03, 0.42, 1)
        _NebulaB  ("Nebula Lit",  Color) = (0.52, 0.18, 0.85, 1)
        _Scale    ("Scale",    Range(0.5,8)) = 2.2
        _Parallax ("Parallax", Range(1,4))   = 1.9
        _Contrast ("Contrast", Range(0.5,4)) = 1.7
        _BaseSpeed("Base Speed", Range(0,0.5)) = 0.045

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
        Blend SrcAlpha One                  // additive
        ColorMask [_ColorMask]

        Pass
        {
            Name "MYSTIC_NEBULA"
        CGPROGRAM
            #pragma vertex MysticVert
            #pragma fragment frag
            #pragma target 3.0
            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP
            #include "MysticCommon.cginc"

            fixed4 _NebulaA, _NebulaB;
            float _Scale, _Parallax, _Contrast, _BaseSpeed;

            fixed4 frag (v2f IN) : SV_Target
            {
                float2 uv = IN.texcoord;
                float t = _Time.y * _Speed * _BaseSpeed;

                // Squash y so the noise cells stay roughly square on a wide plate.
                float2 p = float2(uv.x, uv.y * 0.35) * _Scale;

                float far  = Fbm3(p + float2(t, t * 0.3));
                float near = Fbm2(p * _Parallax + float2(-t * 1.7, t * 0.5) + 31.7);

                float n = saturate(far * 0.65 + near * 0.45);
                n = pow(n, _Contrast);

                float3 rgb = lerp(_NebulaA.rgb, _NebulaB.rgb, saturate(n * 1.2));
                rgb *= n * _Intensity;

                fixed4 col = fixed4(rgb * _Tint.rgb, MysticMask(IN) * n * _Opacity * _Tint.a);
                col *= IN.color;
                MYSTIC_CLIP(col, IN)
                return col;
            }
        ENDCG
        }
    }
    Fallback Off
}
