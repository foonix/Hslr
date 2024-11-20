using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using Unity.Profiling;
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

        [Tooltip("Use an index buffer to reduce vertex shader overhead.  Increases ovreahead when changing the path list length.")]
        public bool useIndexBuffer;

        ComputeBuffer buffer;
        GraphicsBuffer indexBuffer;

        public List<PathNode> nodes;

        private List<uint> indexBufferInput;

        private const int vertsPerNode = 6;

        private static readonly ProfilerMarker renderToMarker = new("Path.RenderTo()");
        private static readonly ProfilerMarker generateIndexBufferMarker = new("Path.GenerateIndexBuffer()");

        public void RenderTo(CommandBuffer cb)
        {
            using var marker = renderToMarker.Auto();

            EnsurePathBufferCapacity();
            int nodeCount = limitCount > 0 ? limitCount : nodes.Count;

            material.SetInteger("_NodeCount", nodeCount);
            material.SetBuffer("PathDataBuffer", buffer);

            cb.SetBufferData(buffer, nodes, 0, 0, nodeCount);

            if (useIndexBuffer)
            {
                MaybeSetupIndexBuffer(cb);
                cb.DrawProcedural(indexBuffer, objectTrs, material, 0, MeshTopology.Triangles, nodeCount * vertsPerNode);
            }
            else
            {
                cb.DrawProcedural(objectTrs, material, 0, MeshTopology.Triangles, nodeCount * vertsPerNode);
            }
        }

        private void EnsurePathBufferCapacity()
        {
            if (buffer is null || buffer.count != nodes.Count)
            {
                buffer?.Dispose();
                buffer = new(nodes.Count, Marshal.SizeOf<PathNode>(), ComputeBufferType.Structured, ComputeBufferMode.Immutable);
            }
        }

        private void MaybeSetupIndexBuffer(CommandBuffer cb)
        {
            using var marker = generateIndexBufferMarker.Auto();

            bool refillBuffer = false;
            int indexBufferSize = nodes.Count * vertsPerNode * 2;
            if (indexBufferInput is null || indexBufferInput.Count > indexBufferSize)
            {
                indexBufferInput ??= new(indexBufferSize);
                indexBufferInput.Capacity = indexBufferSize;
                refillBuffer = true;
            }

            if (indexBuffer is null || indexBuffer.count < indexBufferSize)
            {
                indexBuffer?.Dispose();
                indexBuffer = new(GraphicsBuffer.Target.Index, indexBufferSize, sizeof(int));
            }

            if (!refillBuffer)
            {
                return;
            }

            indexBufferInput.Clear();
            for (uint i = 0; i < indexBufferSize; i++)
            {
                uint segmentNum = i / vertsPerNode;
                uint segmentStart = segmentNum * vertsPerNode;
                // Verts shared between triangles in the same quad are the same vert.
                // Not merging quad endpoints here due to having to sometimes flip the verts depending on the joint angle,
                // which isn't known until the vertex shader runs.
                switch (i % vertsPerNode)
                {
                    case 0:
                    case 3:
                        indexBufferInput.Add(segmentStart);
                        continue;
                    case 1:
                        indexBufferInput.Add(segmentStart + 1);
                        continue;
                    case 2:
                    case 4:
                        indexBufferInput.Add(segmentStart + 2);
                        continue;
                    case 5:
                        indexBufferInput.Add(segmentStart + 5);
                        continue;
                }
            }
            cb.SetBufferData(indexBuffer, indexBufferInput);
        }

        public void Dispose()
        {
            buffer?.Dispose();
            indexBuffer?.Dispose();
        }
    }
}