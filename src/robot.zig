const std = @import("std");
const Allocator = std.mem.Allocator;
const Part = @import("parts.zig").Part;
const Placement = @import("placement.zig").Placement;
const c = @import("c.zig");
const Color = c.Color;
const Ray = c.Ray;
const RayCollision = c.RayCollision;

pub const Robot = struct {
    const PartInstance = struct {
        part: Part,
        placement: Placement,
        color: Color,
    };
    const Parts = std.MultiArrayList(PartInstance);
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

    pub fn at(robot: *Robot, part_index: usize) PartInstance {
        return robot.parts.get(part_index);
    }

    pub fn rayCollision(robot: Robot, ray: Ray) struct { part_index: ?usize, connection: ?Placement } {
        if (robot.parts.len == 0) return .{
            .part_index = null,
            .connection = .{
                .position = .{ 0, 0, -1 },
                .rotation = Placement.Rotation.up,
            },
        };
        const eps = 1e-5;
        var closest_mesh_distance = std.math.floatMax(f32);
        var closest_part_index: ?usize = null;
        for (0..robot.parts.len) |i| {
            const part = robot.parts.get(i);
            const mesh_collision = c.GetRayCollisionMesh(ray, part.part.mesh(), part.placement.mat());
            if (mesh_collision.hit and mesh_collision.distance < closest_mesh_distance) {
                closest_mesh_distance = mesh_collision.distance;
                closest_part_index = i;
            }
        }
        var closest_connection: ?Placement = null;
        if (closest_part_index != null) {
            const max = closest_mesh_distance + eps;
            const min = closest_mesh_distance - eps;
            var closest_connection_distance = max;
            const part = robot.parts.get(closest_part_index.?);
            for (part.part.connections()) |part_connection| {
                const connection = part.placement.place(part_connection);
                const connection_collision = connection.rayCollision(ray);
                if (connection_collision.hit and connection_collision.distance <= closest_connection_distance) {
                    if (connection_collision.distance < min) {
                        closest_connection = null;
                        break;
                    } else {
                        closest_connection_distance = connection_collision.distance;
                        closest_connection = connection;
                    }
                }
            }
        }
        return .{
            .part_index = closest_part_index,
            .connection = closest_connection,
        };
    }
};
