const std = @import("std");
const Allocator = std.mem.Allocator;
const Part = @import("parts.zig").Part;
const Placement = @import("placement.zig").Placement;
const c = @import("c.zig");
const Color = @import("color.zig").Color;
const Ray = c.Ray;
const RayCollision = c.RayCollision;

pub const Options = struct {
    mark_collisions: bool = false,
};

/// for edit mode
pub fn Type(options: Options) type {
    return struct {
        const Robot = @This();
        const PartInstance = struct {
            part: Part,
            placement: Placement,
            color: Color,
            collides: if (options.mark_collisions) bool else void = if (options.mark_collisions) false else {},
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
                const color = if (!options.mark_collisions or !part.collides) part.color.raylib() else c.MAROON;
                part.part.render(part.placement, color, false);
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
                .connection = Placement.connection,
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

        pub fn buildCollision(robot: *Robot, new_part: Part, new_placement: ?Placement) bool {
            var collides = false;
            if (options.mark_collisions) @memset(robot.parts.items(.collides), false);
            if (new_placement == null) return false;
            for (0..robot.parts.len) |i| {
                const old_part = robot.parts.get(i);
                for (new_part.connections()) |new_connection| {
                    const new_connection_placement_inv = new_placement.?.place(new_connection).inv();
                    for (old_part.part.connections()) |old_connection| {
                        const old_connection_placement = old_part.placement.place(old_connection);
                        const diff = new_connection_placement_inv.place(old_connection_placement);
                        const position_matches = @reduce(.And, diff.position == @as(Placement.Position, @splat(0)));
                        const z_axis_matches = diff.rotation.shuffle.mask()[2] == 2;
                        const z_dir_matches = diff.rotation.flip.mask(i8)[2] == 1;
                        if (position_matches and z_axis_matches and z_dir_matches) {
                            if (options.mark_collisions) {
                                collides = true;
                                robot.parts.items(.collides)[i] = true;
                            } else {
                                return true;
                            }
                        }
                    }
                }
            }
            return collides;
        }
    };
}
