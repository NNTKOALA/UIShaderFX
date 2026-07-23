using UnityEngine;
using UnityEngine.UI;

namespace MysticPurple
{
    /// <summary>
    /// Writes the Graphic's rect size (px) into TEXCOORD1 so shaders can do
    /// pixel-accurate work (rounded corners, rim width) without a material per size.
    /// </summary>
    [ExecuteAlways]
    [AddComponentMenu("UI/Effects/UI Rect Size Feeder")]
    [RequireComponent(typeof(RectTransform))]
    public class UIRectSizeFeeder : BaseMeshEffect
    {
        protected override void OnEnable()
        {
            base.OnEnable();
            EnsureCanvasChannel();
        }

        protected override void OnRectTransformDimensionsChange()
        {
            base.OnRectTransformDimensionsChange();
            if (graphic != null)
                graphic.SetVerticesDirty();
        }

        // The Canvas strips unused vertex streams, so TexCoord1 has to be opted into.
        void EnsureCanvasChannel()
        {
            if (graphic == null || graphic.canvas == null) return;
            graphic.canvas.additionalShaderChannels |= AdditionalCanvasShaderChannels.TexCoord1;
        }

        public override void ModifyMesh(VertexHelper vh)
        {
            if (!IsActive()) return;

            EnsureCanvasChannel();

            Rect r = ((RectTransform)transform).rect;
            var size = new Vector4(r.width, r.height, 0f, 0f);

            var vert = new UIVertex();
            for (int i = 0; i < vh.currentVertCount; i++)
            {
                vh.PopulateUIVertex(ref vert, i);
                vert.uv1 = size;
                vh.SetUIVertex(vert, i);
            }
        }
    }
}
