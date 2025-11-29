const c = @import("c.zig").c;

const Box = @import("box.zig");
const Mesh = @import("mesh.zig");

const Ray = @This();

pos: @Vector(3, f32),
dir: @Vector(3, f32),

/// point = ray.pos + ray.dir * hit.dist
pub const Hit = struct {
    dist: f32,
    normal: @Vector(3, f32),
};

pub fn box(ray: Ray, box_: Box) ?Hit {
    // pos + t_0 * dir = min
    // pos + t_1 * dir = max
    const t_0 = (box_.min - ray.pos) / ray.dir;
    const t_1 = (box_.max - ray.pos) / ray.dir;

    const t_min = @min(t_0, t_1);
    const t_max = @max(t_0, t_1);

    const enter = @reduce(.Max, t_min);
    const exit = @reduce(.Min, t_max);
    if (exit < enter) return null;
    if (exit <= 0) return null;
    const t_: @Vector(3, f32) = @splat(enter);
    const one: @Vector(3, f32) = @splat(1);
    const zero: @Vector(3, f32) = @splat(0);
    return .{
        .dist = enter,
        .normal = @select(f32, t_1 == t_, one, zero) - @select(f32, t_0 == t_, one, zero),
    };
}

pub fn mesh(ray: Ray, mesh_: Mesh) ?Hit {
    const r = c.GetRayCollisionMesh(ray.raylib(), mesh_.internal, comptime c.MatrixIdentity());
    if (!r.hit) return null;
    return .{
        .dist = r.distance,
        .normal = .{
            r.normal.x,
            r.normal.y,
            r.normal.z,
        },
    };
}

fn raylib(ray: Ray) c.Ray {
    return .{
        .direction = .{
            .x = ray.dir[0],
            .y = ray.dir[1],
            .z = ray.dir[2],
        },
        .position = .{
            .x = ray.pos[0],
            .y = ray.pos[1],
            .z = ray.pos[2],
        },
    };
}
