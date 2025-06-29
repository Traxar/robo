pub usingnamespace @cImport({
    @cInclude("raylib.h");
    @cInclude("rlgl.h");
    @cInclude("raymath.h");
    @cDefine("RAYGUI_IMPLEMENTATION", {});
    @cInclude("raygui.h");
});

const c = @This();

pub fn toVector3(v: @Vector(3, f32)) c.Vector3 {
    return .{ .x = v[0], .y = v[1], .z = v[2] };
}

pub fn toVector2(v: @Vector(2, f32)) c.Vector2 {
    return .{ .x = v[0], .y = v[1] };
}

pub fn fromVector3(v: c.Vector3) @Vector(3, f32) {
    return .{ v.x, v.y, v.z };
}

pub fn fromVector2(v: c.Vector2) @Vector(2, f32) {
    return .{ v.x, v.y };
}

pub fn Vector3Rotate(v: c.Vector3, mat: c.Matrix) c.Vector3 {
    const x = v.x;
    const y = v.y;
    const z = v.z;
    return .{
        .x = (((mat.m0 * x) + (mat.m4 * y)) + (mat.m8 * z)),
        .y = (((mat.m1 * x) + (mat.m5 * y)) + (mat.m9 * z)),
        .z = (((mat.m2 * x) + (mat.m6 * y)) + (mat.m10 * z)),
    };
}

pub fn CameraRay(camera: c.Camera3D) c.Ray {
    return c.Ray{ .position = camera.position, .direction = c.Vector3Subtract(camera.target, camera.position) };
}

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
