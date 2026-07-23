// Layer 6 - particle material. Draws a soft round dot straight from the quad UV, so
// the dust layer ships without any texture at all.
//
// Fed by UIParticleRenderer, which bakes the ParticleSystem into a CanvasRenderer
// mesh. It therefore uses the standard UI vertex colour path for per-particle tint
// and fade, and does not need the rounded-plate mask (particles are already spawned
// inside the rect).
Shader "UI/Mystic/6 Dust"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Tint      ("Tint",      Color)      = (1,1,1,1)
        _Intensity ("Intensity", Range(0,4)) = 1
        _Opacity   ("Opacity",   Range(0,1)) = 1
        _Softness  ("Softness",  Range(1,8)) = 2.5

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
        _ColorMask ("Color Mask", Float) = 15
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
            Name "MYSTIC_DUST"
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                float4 worldPos : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _ClipRect;
            fixed4 _Tint;
            float _Intensity, _Opacity, _Softness;

            v2f vert (appdata_t v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.worldPos = v.vertex;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = v.texcoord;
                o.color = v.color;
                return o;
            }

            fixed4 frag (v2f IN) : SV_Target
            {
                float2 d = IN.texcoord * 2.0 - 1.0;
                float dot2 = saturate(1.0 - dot(d, d));
                float a = pow(dot2, _Softness);

                fixed4 col = IN.color * _Tint;
                col.rgb *= _Intensity;
                col.a *= a * _Opacity;

                #ifdef UNITY_UI_CLIP_RECT
                col.a *= UnityGet2DClipping(IN.worldPos.xy, _ClipRect);
                #endif

                return col;
            }
        ENDCG
        }
    }
    Fallback Off
}
