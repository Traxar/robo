const c = @import("c.zig").c;

const gpu = @import("gpu.zig");

internal: c.Mesh,

pub fn Cpu(Vertex: type) type {
    return struct {
        const Mesh = @This();

        vertices: []Vertex,
        indices: []u32,
    };
}

pub fn Gpu(Vertex: type) type {
    return struct {
        const Mesh = @This();

        vertices: gpu.VertexBuffer(Vertex, .{}),
        indices: gpu.IndexBuffer(.{}),

        pub fn init(cpu_mesh: Cpu(Vertex)) Mesh {
            var mesh: Mesh = undefined;
            mesh.vertices = try .init(cpu_mesh.vertices);
            errdefer mesh.vertices.deinit();
            mesh.indices = try .init(cpu_mesh.indices);
            errdefer mesh.indices.deinit();
        }

        pub fn deinit(mesh: Mesh) void {
            mesh.indices.deinit();
            mesh.vertices.deinit();
        }

        pub fn render(mesh: Mesh) void {
            c.rlEnableVertexBuffer(mesh.vertices.id);
            c.rlEnableVertexBufferElement(mesh.indices.id);

            c.rlDrawVertexArrayElements(0, @divExact(mesh.indices.len, 3), null);

            @compileError("WIP");
        }
    };
}
