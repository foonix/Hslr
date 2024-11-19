using UnityEngine;
using UnityEngine.Rendering;

namespace Hslr
{
    public class HslrRenderer : MonoBehaviour
    {
        public Path path;

        CommandBuffer cb;

        void Start()
        {
            Camera.onPreRender += OnPreRenderCallback;
        }

        void OnPreRenderCallback(Camera cam)
        {
            if (cam == Camera.main)
            {
                if (cb is null)
                {
                    cb = new()
                    {
                        name = "HslrRenderer"
                    };
                    cam.AddCommandBuffer(CameraEvent.AfterSkybox, cb);
                }

                path.objectTrs = transform.localToWorldMatrix;

                cb.Clear();
                path.RenderTo(cb);
            }
        }

        private void OnDestroy()
        {
            Camera.onPreRender -= OnPreRenderCallback;
            path.Dispose();
        }
    }
}