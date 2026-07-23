using UnityEngine;
using UnityEngine.UI;

namespace MysticPurple
{
    /// <summary>
    /// Draws a ParticleSystem through a CanvasRenderer instead of the ParticleSystemRenderer.
    ///
    /// Why this exists: ParticleSystemRenderer is not drawn at all inside a
    /// Screen Space - Overlay canvas, which is the render mode this project uses. Baking
    /// the particles into UI geometry each frame is the only way to get a real
    /// ParticleSystem to appear there, and it has the side benefit of sorting correctly
    /// against the other UI layers and respecting RectMask2D.
    ///
    /// Cost scales with live particle count, so keep Max Particles small (this effect
    /// ships with 24). The built-in ParticleSystemRenderer is disabled on enable.
    /// </summary>
    [ExecuteAlways]
    [RequireComponent(typeof(ParticleSystem))]
    [AddComponentMenu("UI/Effects/UI Particle Renderer")]
    public class UIParticleRenderer : MaskableGraphic
    {
        ParticleSystem _ps;
        ParticleSystemRenderer _psRenderer;
        ParticleSystem.Particle[] _particles;

        protected override void OnEnable()
        {
            base.OnEnable();
            Bind();
        }

        void Bind()
        {
            _ps = GetComponent<ParticleSystem>();
            _psRenderer = GetComponent<ParticleSystemRenderer>();

            // We own the drawing now; leaving the native renderer on would either draw
            // nothing (Overlay) or double-draw (Camera/World space).
            if (_psRenderer != null) _psRenderer.enabled = false;

            EnsureBuffer();
        }

        void EnsureBuffer()
        {
            int max = _ps != null ? _ps.main.maxParticles : 1;
            if (_particles == null || _particles.Length < max)
                _particles = new ParticleSystem.Particle[Mathf.Max(max, 1)];
        }

        void LateUpdate()
        {
            if (_ps == null) { Bind(); return; }

#if UNITY_EDITOR
            // Particle systems do not tick outside play mode, so step it by hand to keep
            // the effect previewable while editing. restart:false keeps state across calls.
            if (!Application.isPlaying)
            {
                float dt = Time.unscaledDeltaTime > 0f ? Mathf.Min(Time.unscaledDeltaTime, 0.05f) : 0.02f;
                _ps.Simulate(dt, true, false, true);
            }
#endif
            SetVerticesDirty();
        }

        protected override void OnPopulateMesh(VertexHelper vh)
        {
            vh.Clear();
            if (_ps == null) return;

            EnsureBuffer();
            int count = _ps.GetParticles(_particles);
            if (count == 0) return;

            Color32 graphicColor = color;

            for (int i = 0; i < count; i++)
            {
                ParticleSystem.Particle p = _particles[i];

                // simulationSpace is Local, so particle positions are already in this
                // RectTransform's space and map straight onto UI units.
                Vector3 pos = p.position;
                float half = p.GetCurrentSize(_ps) * 0.5f;
                if (half <= 0f) continue;

                Color32 c = Multiply(p.GetCurrentColor(_ps), graphicColor);

                float rot = p.rotation * Mathf.Deg2Rad;
                float cos = Mathf.Cos(rot) * half;
                float sin = Mathf.Sin(rot) * half;

                var right = new Vector3(cos, sin, 0f);
                var up = new Vector3(-sin, cos, 0f);

                int v = vh.currentVertCount;
                vh.AddVert(pos - right - up, c, new Vector2(0f, 0f));
                vh.AddVert(pos - right + up, c, new Vector2(0f, 1f));
                vh.AddVert(pos + right + up, c, new Vector2(1f, 1f));
                vh.AddVert(pos + right - up, c, new Vector2(1f, 0f));

                vh.AddTriangle(v + 0, v + 1, v + 2);
                vh.AddTriangle(v + 2, v + 3, v + 0);
            }
        }

        static Color32 Multiply(Color32 a, Color32 b)
        {
            return new Color32(
                (byte)(a.r * b.r / 255),
                (byte)(a.g * b.g / 255),
                (byte)(a.b * b.b / 255),
                (byte)(a.a * b.a / 255));
        }
    }
}
