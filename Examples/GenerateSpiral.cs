using UnityEngine;

namespace Hslr
{
    [RequireComponent(typeof(HslrRenderer))]
    public class GenerateSpiral : MonoBehaviour
    {
        public int nodeCount = 2000;
        public float density = 100f;
        public float rotateSpeed = 10f;
        public Color color;
        private int lastNodeCount;

        private void Update()
        {
            UpdateSpiral();
            transform.localRotation = Quaternion.Euler(0, Time.timeSinceLevelLoad * rotateSpeed, 0);
        }

        void UpdateSpiral()
        {
            if (nodeCount == lastNodeCount)
            {
                return;
            }

            lastNodeCount = nodeCount;

            var renderer = GetComponent<HslrRenderer>();

            renderer.path.nodes.Clear();
            for (int i = 0; i < nodeCount; i++)
            {
                float param = i / density;
                renderer.path.nodes.Add(new()
                {
                    position = new Vector3(Mathf.Cos(param), Mathf.Sin(param), Mathf.Sin(param * 8) * 0.25f) * param,
                    Color = color
                });
            }
        }
    }
}
