const c = @import("../c.zig").c;
const panic = @import("../util.zig").panic;

const Options = @import("../gpu.zig").BufferUsage;

const Primitives = enum(u32) {
    points = 0x0000,
    lines = 0x0001,
    line_strip = 0x0003,
    triangles = 0x0004,
    triangle_strip = 0x0005,

    fn allow(primitives: Primitives, n: usize) bool {
        return switch (primitives) {
            .points => true,
            .lines => @mod(n, 2) == 0,
            .line_strip => n != 1,
            .triangles => @mod(n, 3) == 0,
            .triangle_strip => n >= 3 or n == 0,
        };
    }
};

const Index = u32;

pub fn Type(primitives: Primitives, options: Options) type {
    if (options.write.by != .cpu) @compileError("options invalid");
    if (options.read.n != .many) @compileError("options invalid");
    return struct {
        const IndexBuffer = @This();
        id: c_uint,
        len: usize,

        pub fn init(indices: []const u32) !IndexBuffer {
            if (!primitives.allow(indices.len)) //TODO move check to use instead of init
                panic("illegal amount of indices found: {}", .{indices.len});
            const id = c.rlLoadVertexBufferElement(
                indices.ptr,
                @intCast(indices.len * @sizeOf(u32)),
                options.write.n == .many,
            );
            if (id == 0) return error.GpuOutOfMemory;
            return .{
                .id = id,
                .len = indices.len,
            };
        }

        pub fn deinit(buffer: *IndexBuffer) void {
            if (buffer.id == 0) panic("buffer was not initialized", .{});
            c.rlUnloadVertexBuffer(buffer.id);
            buffer.id = 0;
        }

        pub fn update(buffer: IndexBuffer, offset: usize, changes: []const u32) void {
            if (options.write.n == .one) @compileError("buffer was specified to be constant");
            if (buffer.id == 0) panic("buffer was not initialized", .{});
            if (offset + changes.len > buffer.len) panic("out of range", .{});
            c.rlUpdateVertexBufferElements(
                buffer.id,
                changes.ptr,
                @intCast(changes.len * @sizeOf(u32)),
                @intCast(offset),
            );
        }

        pub fn activate(buffer: IndexBuffer) void {
            if (buffer.id == 0) panic("buffer was not initialized", .{});
            c.rlEnableVertexBufferElement(buffer.id);
        }
    };
}
