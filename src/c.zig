pub usingnamespace @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
    @cDefine("RAYGUI_IMPLEMENTATION", {});
    @cInclude("raygui.h");
});

const c = @This();

pub fn toVec3(v: @Vector(3, f32)) c.Vector3 {
    return .{ .x = v[0], .y = v[1], .z = v[2] };
}

pub fn toVec2(v: @Vector(2, f32)) c.Vector2 {
    return .{ .x = v[0], .y = v[1] };
}

pub fn fromVec3(v: c.Vector3) @Vector(3, f32) {
    return .{ v.x, v.y, v.z };
}

pub fn fromVec2(v: c.Vector2) @Vector(2, f32) {
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
