const c = @import("c.zig");

pub fn vec(x: f32, y: f32, z: f32) c.Vector3 {
    return .{ .x = x, .y = y, .z = z };
}

pub fn Vector3Rotate(vec3: c.Vector3, mat: c.Matrix) c.Vector3 {
    const x = vec3.x;
    const y = vec3.y;
    const z = vec3.z;
    return .{
        .x = (((mat.m0 * x) + (mat.m4 * y)) + (mat.m8 * z)),
        .y = (((mat.m1 * x) + (mat.m5 * y)) + (mat.m9 * z)),
        .z = (((mat.m2 * x) + (mat.m6 * y)) + (mat.m10 * z)),
    };
}

pub fn CameraRay(camera: c.Camera3D) c.Ray {
    return c.Ray{ .position = camera.position, .direction = c.Vector3Subtract(camera.target, camera.position) };
}

pub inline fn sliceFromArray(array: anytype) []const @typeInfo(@TypeOf(array)).array.child {
    return array[0..@typeInfo(@TypeOf(array)).array.len];
}
