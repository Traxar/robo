const std = @import("std");
const math = std.math;

pub const c = @import("o/c.zig").c;

//Globals
pub const window = @import("o/window.zig");
pub const draw = @import("o/draw.zig");
pub const render = @import("o/render.zig");
pub const gui = @import("o/gui.zig");
pub const cursor = @import("o/cursor.zig");

//Types
pub const Box = @import("o/box.zig");
pub const Rect = @import("o/rect.zig");
pub const Color = @import("o/color.zig");
const Math = @import("o/math.zig");
pub const Matrix = Math.Matrix(3, f32);
pub const Transform = Math.Transform(3, f32);
pub const Camera = @import("o/camera.zig");
pub const Ray = @import("o/ray.zig");
pub const Mesh = @import("o/mesh.zig");

//?
pub const Input = @import("o/input.zig");

pub const Model = struct {
    internal: c.Model,

    pub fn load(fileName: [*c]const u8) Model {
        return .{
            .internal = c.LoadModel(fileName),
        };
    }

    pub fn unload(model: Model) void {
        c.UnloadModel(model.internal);
    }

    pub fn bounds(model: Model) Box {
        const b = c.GetModelBoundingBox(model.internal);
        return .{
            .min = .{ b.min.x, b.min.y, b.min.z },
            .max = .{ b.max.x, b.max.y, b.max.z },
        };
    }
};

pub const Shader = struct {
    internal: c.Shader,

    pub fn load(vert_glsl: [*c]const u8, frag_glsl: [*c]const u8) Shader {
        return .{
            .internal = c.LoadShaderFromMemory(vert_glsl, frag_glsl),
        };
    }

    pub fn unload(shader: Shader) void {
        c.UnloadShader(shader.internal);
    }

    pub fn locationUniform(shader: Shader, name: [*c]const u8) c_int {
        return c.GetShaderLocation(shader.internal, name);
    }

    pub fn locationInput(shader: Shader, name: [*c]const u8) c_int {
        return c.GetShaderLocationAttrib(shader.internal, name);
    }
};

pub fn loadVertexBuffer(T: type, data: []T, dynamic: bool) c_uint {
    return c.rlLoadVertexBuffer(data.ptr, @intCast(data.len * @sizeOf(T)), dynamic);
}

pub fn updateVertexBuffer(vboId: c_uint, T: type, data: []T, offset: usize) void {
    c.rlUpdateVertexBuffer(vboId, data.ptr, @intCast(data.len * @sizeOf(T)), @intCast(offset));
}

/// `stride` and `offset` are relative to the `BaseType`
/// `compSize` defines how many elements of `BaseType` go into this attribute
pub fn setVertexAttribute(attribute: c_int, Type: type, stride: usize, offset: usize) void {
    const compSize = switch (@typeInfo(Type)) {
        .vector => |v| v.len,
        else => 1,
    };
    const BaseType = switch (@typeInfo(Type)) {
        .vector => |v| v.child,
        else => Type,
    };
    const typeId = switch (BaseType) {
        f32 => c.RL_FLOAT,
        else => unreachable, // not implemented. if needed add above
    };
    c.rlSetVertexAttribute(@intCast(attribute), @intCast(compSize), typeId, false, @intCast(stride * @sizeOf(BaseType)), @intCast(offset * @sizeOf(BaseType)));
}
