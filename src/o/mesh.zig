const c = @import("c.zig").c;
const gpu = @import("gpu.zig");

internal: c.Mesh,

pub fn Cpu(Vertex: type) type {
    return struct {
        const Mesh = @This();

        vertices: []Vertex,
        indices: [][3]usize,
    };
}

pub fn Gpu(Vertex: type) type {
    return struct {
        const Mesh = @This();

        vertices: gpu.VertexBuffer(Vertex, .{}),
        indices: gpu.IndexBuffer(.triangles, .{}),
    };
}
