const std = @import("std");
const Allocator = std.mem.Allocator;
const Part = @import("parts.zig").Part;
const Placement = @import("placement.zig").Placement;
const c = @import("c.zig");
const Color = c.Color;
const Ray = c.Ray;
const RayCollision = c.RayCollision;

pub const Robot = struct {
    const Parts = std.MultiArrayList(struct {
        part: Part,
        placement: Placement,
        color: Color,
    });
    parts: Parts,
    gpa: Allocator,

    pub fn init(gpa: Allocator, inital_capacity: usize) !Robot {
        var parts = Parts{};
        try parts.ensureTotalCapacity(gpa, inital_capacity);
        return .{
            .parts = parts,
            .gpa = gpa,
        };
    }

    pub fn deinit(robot: *Robot) void {
        robot.parts.deinit(robot.gpa);
    }

    pub fn render(robot: Robot) void {
        for (0..robot.parts.len) |i| {
            const part = robot.parts.get(i);
            part.part.render(part.placement, part.color, false);
        }
    }

    pub fn add(robot: *Robot, placement: Placement, part: Part, color: Color) !void {
        try robot.parts.append(robot.gpa, .{
            .part = part,
            .placement = placement,
            .color = color,
        });
    }

    pub fn remove(robot: *Robot, part_index: usize) void {
        robot.parts.swapRemove(part_index);
    }

    pub fn rayCollisionConnections(robot: Robot, ray: Ray) ?Placement {
        if (robot.parts.len == 0) return Placement.zero;
        var closest_collision = RayCollision{};
        closest_collision.distance = std.math.floatMax(f32);
        var closest_connection: ?Placement = null;
        for (0..robot.parts.len) |i| {
            const part = robot.parts.get(i);
            for (part.part.connections()) |connection| {
                const global = part.placement.place(connection);
                const collision = global.rayCollision(ray);
                if (collision.hit and collision.distance < closest_collision.distance) {
                    closest_collision = collision;
                    closest_connection = global;
                }
            }
        }
        return closest_connection;
    }

    /// returns index of hit part
    pub fn rayCollisionParts(robot: Robot, ray: Ray) ?usize {
        var closest_collision = RayCollision{};
        closest_collision.distance = std.math.floatMax(f32);
        var closest_part_index: ?usize = null;
        for (0..robot.parts.len) |i| {
            const part = robot.parts.get(i);
            const collision = c.GetRayCollisionMesh(ray, part.part.mesh(), part.placement.mat());
            if (collision.hit and collision.distance < closest_collision.distance) {
                closest_collision = collision;
                closest_part_index = i;
            }
        }
        return closest_part_index;
    }
};
