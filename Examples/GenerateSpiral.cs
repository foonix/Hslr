using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Hslr
{
    [RequireComponent(typeof(HslrRenderer))]
    public class GenerateSpiral : MonoBehaviour
    {
        public int nodeCount = 2000;
        private int lastNodeCount;

        private void Update()
        {
            UpdateSpiral();
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
                float param = i / 100f;
                renderer.path.nodes.Add(new()
                {
                    position = new Vector3(Mathf.Cos(param), Mathf.Sin(param), Mathf.Sin(param * 8) * 0.25f) * param,
                    color = Color.white,
                });
            }
        }
    }
}
