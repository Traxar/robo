const c = @import("../c.zig").c;
const panic = @import("../util.zig").panic;
const convert = @import("../convert.zig");

const Options = @import("../gpu.zig").BufferUsage;

pub fn Type(Entry: type, options: Options) type {
    return struct {
        const StorageBuffer = @This();
        id: c_uint,
        len: usize,

        pub fn init(entries: []const Entry) !StorageBuffer {
            const id = c.rlLoadShaderBuffer(
                @intCast(entries.len * @sizeOf(Entry)),
                if (options.write.by == .cpu) entries.ptr else null,
                convert.bufferUsage(options),
            );
            if (id == 0) return error.GpuOutOfMemory;
            return .{
                .id = id,
                .len = entries.len,
            };
        }

        pub fn deinit(buffer: *StorageBuffer) void {
            if (buffer.id == 0) panic("buffer was not initialized", .{});
            c.rlUnloadVertexBuffer(buffer.id);
            buffer.id = 0;
        }

        pub fn update(buffer: StorageBuffer, offset: usize, changes: []const Entry) void {
            if (options.write.by != .cpu) @compileError("buffer was specified to not allow updates by the cpu");
            if (options.write.n == .one) @compileError("buffer was specified to not allow updates");
            if (buffer.id == 0) panic("buffer was not initialized", .{});
            if (offset + changes.len > buffer.len) panic("out of range", .{});
            c.rlUpdateVertexBuffer(
                buffer.id,
                changes.ptr,
                @intCast(changes.len * @sizeOf(Entry)),
                @intCast(offset),
            );
        }

        pub fn activate(buffer: StorageBuffer) void {
            if (buffer.id == 0) panic("buffer was not initialized", .{});
            c.rlEnableVertexBuffer(buffer.id);
        }
    };
}
