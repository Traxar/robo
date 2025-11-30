const c = @import("c.zig").c;

pub const VertexBuffer = @import("gpu/vertexBuffer.zig").Type;
pub const IndexBuffer = @import("gpu/indexBuffer.zig").Type;
pub const StorageBuffer = @import("gpu/storageBuffer.zig").Type;

pub const BufferUsage = struct {
    write: Use = .{ .by = .cpu, .n = .one },
    read: Use = .{ .by = .gpu, .n = .many },

    const Use = struct {
        by: ProcessingUnit,
        n: Amount,

        const ProcessingUnit = enum { cpu, gpu };
        const Amount = enum { one, many };
    };
};
