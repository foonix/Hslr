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
        public int capacity;
        public int used;
        ComputeBuffer buffer;

        public List<PathNode> nodes;

        public void RenderTo(CommandBuffer cb)
        {
            if (buffer is null)
            {
                buffer = new(nodes.Count, Marshal.SizeOf<PathNode>(), ComputeBufferType.Structured, ComputeBufferMode.Immutable);
            }
            int segmentCount = nodes.Count;
            material.SetInteger("_SegmentCount", segmentCount);
            material.SetBuffer("PathDataBuffer", buffer);

            cb.SetBufferData(buffer, nodes);
            cb.DrawProcedural(objectTrs, material, 0, MeshTopology.Triangles, segmentCount * 6);
        }

        public void Dispose()
        {
            buffer.Dispose();
        }
    }
}