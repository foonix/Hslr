using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.Rendering;

namespace Hslr
{
    [Serializable]
    public struct Path
    {
        public Matrix4x4 objectTrs;
        public Material material;

        [Tooltip("Limit the number of nodes drawn to less than the entire buffer.  This allows changing the number of segments drawn without resizing the buffer.")]
        public int limitCount;

        ComputeBuffer buffer;

        public List<PathNode> nodes;

        public void RenderTo(CommandBuffer cb)
        {
            if (buffer is null || buffer.count != nodes.Count)
            {
                buffer?.Dispose();
                buffer = new(nodes.Count, Marshal.SizeOf<PathNode>(), ComputeBufferType.Structured, ComputeBufferMode.Immutable);
            }

            int nodeCount = limitCount > 0 ? limitCount : nodes.Count;

            material.SetInteger("_NodeCount", nodeCount);
            material.SetBuffer("PathDataBuffer", buffer);

            cb.SetBufferData(buffer, nodes);
            cb.DrawProcedural(objectTrs, material, 0, MeshTopology.Triangles, (nodeCount) * 6);
        }

        public void Dispose()
        {
            buffer?.Dispose();
        }
    }
}