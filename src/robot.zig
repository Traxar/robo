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

        pub fn init(gpa: Allocator, inital_capacity: usize) !Robot {
            var parts = Parts{};
            try parts.ensureTotalCapacity(gpa, inital_capacity);
            return .{
                .parts = parts,
            };
        }

        pub fn deinit(robot: *Robot, gpa: Allocator) void {
            robot.parts.deinit(gpa);
        }

        pub fn render(robot: Robot, mode: Part.RenderOptions.Mode) void {
            for (0..robot.parts.len) |i| {
                const part = robot.parts.get(i);
                const color = if (!options.mark_collisions or !part.collides) part.color.raylib() else Color.collision;
                part.part.render(part.placement, color, .{ .mode = mode });
            }
        }

        pub fn add(robot: *Robot, gpa: Allocator, placement: Placement, part: Part, color: Color) !void {
            try robot.parts.append(gpa, .{
                .part = part,
                .placement = placement,
                .color = color,
            });
        }

        pub fn remove(robot: *Robot, part_index: usize) void {
            robot.parts.swapRemove(part_index);
        }

        pub fn at(robot: Robot, part_index: usize) PartInstance {
            return robot.parts.get(part_index);
        }

        const SaveFormat = struct {
            parts: []Part,
            placements: []Placement,
            colors: []Color,
        };

        pub fn save(robot: Robot) !void {
            var save_format: SaveFormat = undefined;
            const enum_literals = .{ .part, .placement, .color };
            const slice_names = .{ "parts", "placements", "colors" };
            inline for (enum_literals, slice_names) |e, s| {
                @field(save_format, s) = robot.parts.items(e);
            }
            var file = try std.fs.cwd().createFile("ro.bot", .{});
            defer file.close();
            try std.zon.stringify.serialize(save_format, .{}, file.writer());
        }

        pub fn load(path: []const u8, gpa: Allocator) !Robot {
            const source = try std.fs.cwd().readFileAllocOptions(gpa, path, 1_000_000, null, 1, 0);
            defer gpa.free(source);
            const save_format = try std.zon.parse.fromSlice(SaveFormat, gpa, source, null, .{});
            var robot = try Robot.init(gpa, save_format.parts.len);
            robot.parts.len = save_format.parts.len;
            const enum_literals = .{ .part, .placement, .color };
            const slice_names = .{ "parts", "placements", "colors" };
            inline for (enum_literals, slice_names) |e, s| {
                @memcpy(robot.parts.items(e), @field(save_format, s));
                gpa.free(@field(save_format, s));
            }
            return robot;
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
                const mesh_collision = c.GetRayCollisionMesh(ray, part.part.mesh(), part.placement.mat(1));
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
                    const connection = part.placement.place(part_connection) catch unreachable;
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

        pub fn buildCollision(robot: *Robot, new_part: Part, new_placement_: ?Placement) bool {
            var collides = false;
            if (options.mark_collisions) @memset(robot.parts.items(.collides), false);
            if (new_placement_ == null) return false;
            const new_placement = new_placement_.?;
            for (0..robot.parts.len) |i| outer: {
                const old_part = robot.parts.get(i);
                //connections:
                for (new_part.connections()) |new_connection| {
                    const new_connection_placement_inv = (new_placement.place(new_connection) catch {
                        collides = true;
                        if (!options.mark_collisions) break :outer else continue;
                    }).inv();
                    for (old_part.part.connections()) |old_connection| {
                        const old_connection_placement = old_part.placement.place(old_connection) catch unreachable;
                        const diff = new_connection_placement_inv.place(old_connection_placement) catch continue;
                        const position_matches = @reduce(.And, diff.position == @as(Placement.Position, @splat(0)));
                        const z_axis_matches = diff.rotation.shuffle.mask()[2] == 2;
                        const z_dir_matches = diff.rotation.flip.mask(i8)[2] == 1;
                        if (position_matches and z_axis_matches and z_dir_matches) {
                            collides = true;
                            if (!options.mark_collisions) break :outer;
                            robot.parts.items(.collides)[i] = true;
                        }
                    }
                }
                //buildboxes:
                const newToOld = new_placement.inv().place(old_part.placement) catch continue;
                if (new_part.buildBox().collides(newToOld, old_part.part.buildBox())) {
                    collides = true;
                    if (!options.mark_collisions) break :outer;
                    robot.parts.items(.collides)[i] = true;
                }
            }
            return collides;
        }
    };
}
