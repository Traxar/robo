const c = @import("../c.zig").c;
const panic = @import("../util.zig").panic;

const Options = @import("../gpu.zig").BufferUsage;

pub fn Type(Vertex: type, options: Options) type {
    if (options.write.by != .cpu) @compileError("options invalid");
    if (options.read.n != .many) @compileError("options invalid");
    return struct {
        const VertexBuffer = @This();
        id: c_uint,
        len: usize,

        pub fn init(vertices: []const Vertex) !VertexBuffer {
            const id = c.rlLoadVertexBuffer(
                vertices.ptr,
                @intCast(vertices.len * @sizeOf(Vertex)),
                options.write.n == .many,
            );
            if (id == 0) return error.GpuOutOfMemory;
            return .{
                .id = id,
                .len = vertices.len,
            };
        }

        pub fn deinit(buffer: *VertexBuffer) void {
            if (buffer.id == 0) panic("buffer was not initialized", .{});
            c.rlUnloadVertexBuffer(buffer.id);
            buffer.id = 0;
        }

        pub fn update(buffer: VertexBuffer, offset: usize, changes: []const Vertex) void {
            if (options.write.n == .one) @compileError("buffer was specified to be constant");
            if (buffer.id == 0) panic("buffer was not initialized", .{});
            if (offset + changes.len > buffer.len) panic("out of range", .{});
            c.rlUpdateVertexBuffer(
                buffer.id,
                changes.ptr,
                @intCast(changes.len * @sizeOf(Vertex)),
                @intCast(offset),
            );
        }

        pub fn activate(buffer: VertexBuffer) void {
            if (buffer.id == 0) panic("buffer was not initialized", .{});
            c.rlEnableVertexBuffer(buffer.id);
        }
    };
}
