# Highly Simplified Line Renderer

A Unity package for drawing object lines in screen space.

## Simplifying assumptions

- The mesh is likely to change every frame, so delete the mesh generation step.
- Vertex shaders can use ComputeBufers, which allows them to look ahead/behind in a line path sequence.
- Calculating data sequentially on the CPU is slower than in parallel on the GPU, so do the equivalent to mesh generation in the vertex shader.

### Advantages:
- Main thread time in unity is minimized.  Only updated lines data needs to be copied.
- The transfer process is pushed down to Unity C++ level, out of managed code.

### Disadvantages:
- Needs to be driven by a DrawProcedural call.
- Vertex shader is more expensive, which is a disadvantage on static lines.

# Credits

Credit to [devOdico/GoodLines](https://github.com/devOdico/GoodLines) for pulling together the necessary vertex math, which is in turn based on [Drawing Lines is Hard](https://mattdesl.svbtle.com/drawing-lines-is-hard).

Thank you to various commenters in [this libcinder forum thread](https://web.archive.org/web/20160313110702/http://forum.libcinder.org/topic/smooth-thick-lines-using-geometry-shader).

LICENSE: MIT
