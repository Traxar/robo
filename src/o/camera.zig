const std = @import("std");
const c = @import("c.zig").c;
const convert = @import("convert.zig");

const Ray = @import("ray.zig");

const Camera = @This();
const F = f32;

position: @Vector(3, F),
rotation: @Vector(2, F), // yaw, pitch
options: Options = .{},

pub const Options = struct {
    fovy: F = 45,
    forward_relative_to_camera: bool = true,
    up_relative_to_camera: bool = true,
};

pub fn forward(sin: @Vector(2, F), cos: @Vector(2, F), relative_to_camera: bool) @Vector(3, F) {
    return if (relative_to_camera)
        .{
            cos[1] * -sin[0],
            cos[1] * cos[0],
            sin[1],
        }
    else
        .{
            -sin[0],
            cos[0],
            0,
        };
}

pub fn right(sin: @Vector(2, F), cos: @Vector(2, F)) @Vector(3, F) {
    return .{
        cos[0],
        sin[0],
        0,
    };
}

pub fn up(sin: @Vector(2, F), cos: @Vector(2, F), relative_to_camera: bool) @Vector(3, F) {
    return if (relative_to_camera)
        .{
            sin[1] * sin[0],
            sin[1] * -cos[0],
            cos[1],
        }
    else
        .{ 0, 0, 1 };
}

pub fn update(camera: *Camera, movement: @Vector(3, F), rotation: @Vector(2, F), options: Options) void {
    camera.rotation += rotation;
    camera.repairRotation();
    const sin = @sin(camera.rotation);
    const cos = @cos(camera.rotation);
    camera.position += @as(@Vector(3, F), @splat(movement[0])) * right(sin, cos);
    camera.position += @as(@Vector(3, F), @splat(movement[1])) * forward(sin, cos, options.forward_relative_to_camera);
    camera.position += @as(@Vector(3, F), @splat(movement[2])) * up(sin, cos, options.up_relative_to_camera);
}

pub fn target(camera: *Camera, position: @Vector(3, F)) void {
    const diff = position - camera.position;
    const norm = @reduce(.Add, diff * diff);
    if (norm <= 0) return;
    const dir = diff / @as(@Vector(3, F), @splat(@sqrt(norm)));
    camera.rotation[1] = std.math.asin(dir[2]);
    camera.rotation[0] = std.math.atan2(-dir[0], dir[1]);
}

fn repairRotation(camera: *Camera) void {
    camera.rotation[0] = @mod(camera.rotation[0], 2 * std.math.pi);
    camera.rotation[1] = @max(-std.math.pi / 2.0, @min(std.math.pi / 2.0, camera.rotation[1]));
}

pub fn rayFromScreen(camera: Camera, screen_position: @Vector(2, F)) Ray {
    const res = c.GetScreenToWorldRay(
        .{
            .x = screen_position[0],
            .y = screen_position[1],
        },
        convert.camera(camera),
    );
    return .{
        .dir = .{
            res.direction.x,
            res.direction.y,
            res.direction.z,
        },
        .pos = .{
            res.position.x,
            res.position.y,
            res.position.z,
        },
    };
}

pub fn ray(camera: Camera) Ray {
    const sin = @sin(camera.rotation);
    const cos = @cos(camera.rotation);
    return .{
        .pos = camera.position,
        .dir = forward(sin, cos, true),
    };
}
