const c = @import("c.zig").c;
const Color = @import("color.zig");
const Camera = @import("camera.zig");
const Rect = @import("rect.zig");
const BufferUsage = @import("gpu.zig").BufferUsage;
//conversions
pub fn color(color_: Color) c.Color {
    return .{
        .r = color_.rgba[0],
        .g = color_.rgba[1],
        .b = color_.rgba[2],
        .a = color_.rgba[3],
    };
}

fn Vector(Vector_: type) type {
    return switch (Vector_) {
        @Vector(2, f32) => c.Vector2,
        @Vector(3, f32) => c.Vector3,
        @Vector(4, f32) => c.Vector4,
        else => unreachable,
    };
}

pub fn vector(vector_: anytype) Vector(@TypeOf(vector_)) {
    return switch (@TypeOf(vector_)) {
        @Vector(2, f32) => .{
            .x = vector_[0],
            .y = vector_[1],
        },
        @Vector(3, f32) => .{
            .x = vector_[0],
            .y = vector_[1],
            .z = vector_[2],
        },
        @Vector(4, f32) => .{
            .x = vector_[0],
            .y = vector_[1],
            .z = vector_[2],
            .w = vector_[3],
        },
        else => unreachable,
    };
}

pub fn camera(camera_: Camera) c.Camera3D {
    const sin = @sin(camera_.rotation);
    const cos = @cos(camera_.rotation);
    return .{
        .position = vector(camera_.position),
        .target = vector(camera_.position + Camera.forward(sin, cos, true)),
        .up = vector(Camera.up(sin, cos, true)),
        .fovy = camera_.options.fovy,
        .projection = c.CAMERA_PERSPECTIVE,
    };
}

pub fn rect(rect_: Rect) c.Rectangle {
    return .{
        .x = rect_.min[0],
        .y = rect_.min[1],
        .width = rect_.max[0] - rect_.min[0],
        .height = rect_.max[1] - rect_.min[1],
    };
}

pub inline fn bufferUsage(usage: BufferUsage) c_int {
    comptime {
        if (usage.write.by == .cpu and usage.read.by == .cpu) @compileError("invalid buffer useage");
        if (usage.write.n == .many and usage.read.n == .one) @compileError("invalid buffer useage");

        var code: c_int = 0x88E0; //RL_STREAM_DRAW
        if (usage.write.by == .gpu) {
            switch (usage.read.by) {
                .cpu => code |= 1, //RL_xxx_READ
                .gpu => code |= 2, //RL_xxx_COPY
            }
        }
        if (usage.read.n == .many) {
            switch (usage.write.n) {
                .one => code |= 4, //RL_STATIC_xxx
                .many => code |= 8, //RL_DYNAMIC_xxx
            }
        }
        return code;
    }
}
