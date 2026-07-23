using UnityEngine;
using UnityEngine.UI;

namespace MysticPurple
{
    /// <summary>
    /// Drives the "UI/FX/Cartoon Golden" shader from a small, designer-facing parameter
    /// set. Sits on the same GameObject as the Image that renders the trail.
    ///
    /// The effect is entirely procedural: no flipbook, no particle simulation, one draw
    /// call. The only texture is a 64x1 ramp baked from <see cref="colorGradient"/>.
    ///
    /// Why no ParticleSystem: this Canvas renders in Screen Space - Overlay, where
    /// ParticleSystemRenderer is not drawn at all. Sparks are generated in the fragment
    /// shader instead, which also avoids a second draw call and any CPU/GC cost.
    /// </summary>
    [ExecuteAlways]
    [RequireComponent(typeof(Image))]
    [RequireComponent(typeof(UIRectSizeFeeder))]
    [AddComponentMenu("UI/Effects/Cartoon Golden Trail")]
    [DisallowMultipleComponent]
    public class CartoonGoldenTrail : MonoBehaviour
    {
        [Header("Main Parameters")]

        [Tooltip("How fast the golden energy travels left to right. The animation is an " +
                 "infinite loop driven by shader time, so it never stops or restarts.")]
        [Range(0f, 4f)] public float flowSpeed = 1.0f;

        [Tooltip("Brightness of the trail. Glow is baked into the shader because " +
                 "Screen Space - Overlay UI never receives URP post-process Bloom.")]
        [Range(0f, 6f)] public float glowIntensity = 1.9f;

        [Tooltip("Density of the golden spark particles riding along the trail.")]
        [Range(0f, 3f)] public float particleAmount = 1.2f;

        [Tooltip("Vertical thickness of the trail, as a fraction of the rect height.")]
        [Range(0.05f, 1f)] public float trailWidth = 0.55f;

        [Tooltip("Palette, sampled by brightness: left = soft outer edge, " +
                 "right = hot core. Baked to a 64x1 ramp texture.")]
        public Gradient colorGradient = DefaultGradient();

        [Tooltip("How much noise distorts the wave and the flame shape. " +
                 "0 = clean sine wave, 1 = strongly broken up.")]
        [Range(0f, 1f)] public float noiseStrength = 0.4f;

        // Shader property IDs, resolved once. Cheaper than string lookups per apply.
        static readonly int IdRamp      = Shader.PropertyToID("_RampTex");
        static readonly int IdFlowSpeed = Shader.PropertyToID("_FlowSpeed");
        static readonly int IdGlow      = Shader.PropertyToID("_GlowIntensity");
        static readonly int IdParticles = Shader.PropertyToID("_ParticleAmount");
        static readonly int IdWidth     = Shader.PropertyToID("_TrailWidth");
        static readonly int IdNoise     = Shader.PropertyToID("_NoiseStrength");

        const int RampWidth = 64;   // well under the 512 budget; 64 steps is plenty here

        Image _image;
        Material _runtimeMaterial;
        Texture2D _rampTexture;

        void OnEnable()
        {
            _image = GetComponent<Image>();
            Apply();
        }

        void OnDisable()
        {
            // Editor and player both need the generated objects released, or every
            // enable/disable cycle leaks a material and a texture.
            SafeDestroy(ref _runtimeMaterial);
            SafeDestroy(ref _rampTexture);
        }

        void OnValidate()
        {
            if (isActiveAndEnabled) Apply();
        }

        /// <summary>Push the current parameters into the material. Safe to call any time.</summary>
        public void Apply()
        {
            if (_image == null) _image = GetComponent<Image>();
            if (_image == null || _image.material == null) return;

            // Instance the shared material so tweaking one trail does not edit the asset
            // (and therefore every other trail using it).
            if (_runtimeMaterial == null || _runtimeMaterial.shader != _image.material.shader)
            {
                SafeDestroy(ref _runtimeMaterial);
                _runtimeMaterial = new Material(_image.material) { hideFlags = HideFlags.DontSave };
            }

            BakeGradient();

            _runtimeMaterial.SetTexture(IdRamp, _rampTexture);
            _runtimeMaterial.SetFloat(IdFlowSpeed, flowSpeed);
            _runtimeMaterial.SetFloat(IdGlow, glowIntensity);
            _runtimeMaterial.SetFloat(IdParticles, particleAmount);
            _runtimeMaterial.SetFloat(IdWidth, trailWidth);
            _runtimeMaterial.SetFloat(IdNoise, noiseStrength);

            _image.material = _runtimeMaterial;
        }

        void BakeGradient()
        {
            if (_rampTexture == null)
            {
                _rampTexture = new Texture2D(RampWidth, 1, TextureFormat.RGBA32, false, false)
                {
                    wrapMode = TextureWrapMode.Clamp,   // clamp: lum of 0 or 1 must not wrap
                    filterMode = FilterMode.Bilinear,
                    hideFlags = HideFlags.DontSave,
                    name = "CartoonGoldenRamp"
                };
            }

            var pixels = new Color[RampWidth];
            for (int i = 0; i < RampWidth; i++)
                pixels[i] = colorGradient.Evaluate(i / (float)(RampWidth - 1));

            _rampTexture.SetPixels(pixels);
            _rampTexture.Apply(false, false);
        }

        static void SafeDestroy<T>(ref T obj) where T : Object
        {
            if (obj == null) return;
            if (Application.isPlaying) Destroy(obj);
            else DestroyImmediate(obj);
            obj = null;
        }

        /// <summary>Warm gold ramp: ember -> orange -> gold -> near-white core.</summary>
        static Gradient DefaultGradient()
        {
            var g = new Gradient();
            g.SetKeys(
                new[]
                {
                    new GradientColorKey(new Color(0.55f, 0.10f, 0.00f), 0.00f),
                    new GradientColorKey(new Color(1.00f, 0.42f, 0.03f), 0.35f),
                    new GradientColorKey(new Color(1.00f, 0.78f, 0.14f), 0.70f),
                    new GradientColorKey(new Color(1.00f, 0.96f, 0.78f), 1.00f),
                },
                new[] { new GradientAlphaKey(1f, 0f), new GradientAlphaKey(1f, 1f) });
            return g;
        }
    }
}
