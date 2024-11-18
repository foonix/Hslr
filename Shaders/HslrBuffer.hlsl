#ifndef HSLRINCLUDE_INCLUDED
#define HSLRINCLUDE_INCLUDED

struct NodeData
{
    float3 position;
    float4 color;
};

struct NodeContext
{
    NodeData thisNode;
    NodeData nextNode;
    NodeData prevNode;
};

StructuredBuffer<NodeData> PathDataBuffer;

void GetVertNodeIdsWrapped(uint vertexID, uint nodeCount, out uint previous, out uint this, out uint next)
{
    this = vertexID / 6;
    
    // these verts are on the next node.
    switch (vertexID % 6)
    {
        case 2:
        case 4:
        case 5:
            this += 1;
            break;
    }
    
    // wrap end to beginning
    if (this >= nodeCount)
    {
        this -= nodeCount;
    }

    next = this + 1;
    
    if (this == 0)
    {
        // wrap beginning to end
        previous = nodeCount - 1;
    }
    else
    {
        previous = this - 1;
    }
}

// gets the previous/current/next data for the node the current vertex belongs to.
// note: a given triangle/quad will have verts on different nodes.
NodeContext ReadFromBuffer(uint vertexID, uint nodeCount)
{
    NodeContext context;
    
    uint previous;
    uint this;
    uint next;
    GetVertNodeIdsWrapped(vertexID, nodeCount, previous, this, next);
    
    context.prevNode = PathDataBuffer[previous];
    context.thisNode = PathDataBuffer[this];
    context.nextNode = PathDataBuffer[next];
    
    return context;
}

float GetVertThicknessSign(uint vertexID)
{
    switch (vertexID % 6)
    {
        case 0:
        case 3:
        case 5:
            return -1;
    }
    return 1;
}
#endif
