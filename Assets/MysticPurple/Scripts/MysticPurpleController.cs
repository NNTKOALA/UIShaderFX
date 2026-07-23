using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace MysticPurple
{
    /// <summary>
    /// Inspector front-end for the layered "Mystic Purple" effect.
    ///
    /// The effect is seven independent layers rather than one shader, so each can be
    /// retimed, recoloured or switched off on its own. Every layer shader honours the
    /// same four properties (_Tint, _Speed, _Intensity, _Opacity), which is what lets
    /// one controller drive all of them without knowing what each layer does.
    ///
    /// Keeping the speeds unequal is the point: matched speeds make the whole plate
    /// pulse as one object, which is what makes procedural VFX look synthetic.
    /// </summary>
    [ExecuteAlways]
    [AddComponentMenu("UI/Effects/Mystic Purple Controller")]
    [DisallowMultipleComponent]
    public class MysticPurpleController : MonoBehaviour
    {
        [System.Serializable]
        public class Layer
        {
            [Tooltip("The Image (or UIParticleRenderer) that draws this layer.")]
            public Graphic target;

            [Tooltip("The material asset this layer is built from. Runtime instances are " +
                     "created from this, never from Graphic.material - a destroyed " +
                     "instance makes Graphic.material fall back to UI/Default, which would " +
                     "silently lose the layer's shader.")]
            public Material sharedMaterial;

            public bool enabled = true;

            [Tooltip("Multiplies the layer's own colours. Alpha scales the layer too.")]
            [ColorUsage(true, true)] public Color tint = Color.white;

            [Tooltip("Animation rate for this layer alone. Deliberately different per " +
                     "layer so the motion never lines up.")]
            [Range(0f, 4f)] public float speed = 1f;

            [Range(0f, 4f)] public float intensity = 1f;
            [Range(0f, 1f)] public float opacity = 1f;
        }

        [System.Serializable]
        public class DustLayer
        {
            public ParticleSystem system;
            public UIParticleRenderer renderer;
            public Material sharedMaterial;
            public bool enabled = true;

            [ColorUsage(true, true)] public Color tint = Color.white;
            [Range(0f, 4f)] public float intensity = 1f;
            [Range(0f, 1f)] public float opacity = 1f;

            [Tooltip("Particles spawned per second.")]
            [Range(0f, 60f)] public float emissionRate = 9f;

            [Range(0.1f, 8f)] public float lifetime = 3.5f;
            [Range(0.5f, 20f)] public float size = 5f;
            [Range(0f, 60f)] public float driftSpeed = 12f;
        }

        [Header("1 - Dark background gradient")]
        public Layer background = new Layer { speed = 0f, opacity = 1f };

        [Header("2 - Slow nebula")]
        public Layer nebula = new Layer { speed = 0.6f, intensity = 1f, opacity = 0.75f };

        [Header("3 - Magical smoke (dissolve)")]
        public Layer smoke = new Layer { speed = 0.85f, intensity = 1f, opacity = 0.8f };

        [Header("4 - Energy ribbons")]
        public Layer ribbons = new Layer { speed = 1.3f, intensity = 1f, opacity = 1f };

        [Header("5 - Energy pulses")]
        public Layer pulses = new Layer { speed = 1f, intensity = 1f, opacity = 1f };

        [Header("6 - Glowing dust particles")]
        public DustLayer dust = new DustLayer();

        [Header("7 - Additive bloom glow")]
        public Layer glow = new Layer { speed = 0.45f, intensity = 1.4f, opacity = 0.85f };

        // Bumped whenever the material-handling logic changes, so a diagnostic can tell
        // whether the assembly actually reloaded.
        public const string Version = "v2-no-editmode-instancing";

        static readonly int IdTint = Shader.PropertyToID("_Tint");
        static readonly int IdSpeed = Shader.PropertyToID("_Speed");
        static readonly int IdIntensity = Shader.PropertyToID("_Intensity");
        static readonly int IdOpacity = Shader.PropertyToID("_Opacity");

        // One instanced material per layer, so editing this prefab instance never writes
        // back to the shared material assets.
        readonly Dictionary<Graphic, Material> _instances = new Dictionary<Graphic, Material>();

        void OnEnable() { Apply(); }
        void OnValidate() { if (isActiveAndEnabled) Apply(); }
        void OnDisable() { ReleaseInstances(); }

        /// <summary>Push every layer's settings into its material. Safe to call any time.</summary>
        public void Apply()
        {
            ApplyLayer(background);
            ApplyLayer(nebula);
            ApplyLayer(smoke);
            ApplyLayer(ribbons);
            ApplyLayer(pulses);
            ApplyLayer(glow);
            ApplyDust();
        }

        void ApplyLayer(Layer layer)
        {
            if (layer == null || layer.target == null) return;

            if (layer.target.gameObject.activeSelf != layer.enabled)
                layer.target.gameObject.SetActive(layer.enabled);
            if (!layer.enabled) return;

            Material mat = GetInstance(layer.target, layer.sharedMaterial);
            if (mat == null) return;

            if (mat.HasProperty(IdTint)) mat.SetColor(IdTint, layer.tint);
            if (mat.HasProperty(IdSpeed)) mat.SetFloat(IdSpeed, layer.speed);
            if (mat.HasProperty(IdIntensity)) mat.SetFloat(IdIntensity, layer.intensity);
            if (mat.HasProperty(IdOpacity)) mat.SetFloat(IdOpacity, layer.opacity);
        }

        void ApplyDust()
        {
            if (dust == null) return;

            if (dust.renderer != null)
            {
                if (dust.renderer.gameObject.activeSelf != dust.enabled)
                    dust.renderer.gameObject.SetActive(dust.enabled);

                Material mat = GetInstance(dust.renderer, dust.sharedMaterial);
                if (mat != null)
                {
                    if (mat.HasProperty(IdTint)) mat.SetColor(IdTint, dust.tint);
                    if (mat.HasProperty(IdIntensity)) mat.SetFloat(IdIntensity, dust.intensity);
                    if (mat.HasProperty(IdOpacity)) mat.SetFloat(IdOpacity, dust.opacity);
                }
            }

            if (!dust.enabled || dust.system == null) return;

            var emission = dust.system.emission;
            emission.rateOverTime = dust.emissionRate;

            var main = dust.system.main;
            main.startLifetime = dust.lifetime;
            main.startSize = dust.size;
            main.startSpeed = dust.driftSpeed;
        }

        Material GetInstance(Graphic target, Material shared)
        {
            if (target == null) return null;

            // With no shared reference to rebuild from, write to whatever the Graphic
            // already has rather than instancing. Instancing here would be unrecoverable:
            // once the instance is destroyed the original assignment is gone.
            if (shared == null) return target.material;

            // Outside play mode, drive the shared asset directly and never instance.
            // A runtime instance is hideFlags.DontSave, so if a prefab or scene is saved
            // while one is assigned, Unity cannot serialize the reference: it writes null
            // and the Graphic silently falls back to UI/Default on reload.
            //
            // Trade-off: two instances of this prefab share one look while editing, and
            // only diverge in play mode. Duplicate the materials if you need them to
            // differ in the editor too.
            if (!Application.isPlaying)
            {
                if (target.material != shared) target.material = shared;
                return shared;
            }

            if (_instances.TryGetValue(target, out Material cached) && cached != null
                && cached.shader == shared.shader)
            {
                if (target.material != cached) target.material = cached;
                return cached;
            }

            DestroySafe(cached);
            var inst = new Material(shared) { hideFlags = HideFlags.DontSave };
            target.material = inst;
            _instances[target] = inst;
            return inst;
        }

        void ReleaseInstances()
        {
            // Restore the shared material *before* destroying the instance. Skipping this
            // leaves Graphic.material pointing at a destroyed object, which resolves to
            // UI/Default and permanently loses the layer's shader.
            RestoreShared(background); RestoreShared(nebula); RestoreShared(smoke);
            RestoreShared(ribbons); RestoreShared(pulses); RestoreShared(glow);
            if (dust != null && dust.renderer != null && dust.sharedMaterial != null)
                dust.renderer.material = dust.sharedMaterial;

            foreach (var kv in _instances) DestroySafe(kv.Value);
            _instances.Clear();
        }

        static void RestoreShared(Layer layer)
        {
            if (layer == null || layer.target == null || layer.sharedMaterial == null) return;
            layer.target.material = layer.sharedMaterial;
        }

        static void DestroySafe(Object o)
        {
            if (o == null) return;
            if (Application.isPlaying) Destroy(o); else DestroyImmediate(o);
        }
    }
}
