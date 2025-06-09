const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @import("c.zig");
const Placement = @import("placement.zig").Placement;
const Robot = @import("robot.zig").Type(.{ .mark_collisions = false });
const BuildBox = @import("buildbox.zig").BuildBox;
const misc = @import("misc.zig");

var assets: [@typeInfo(Part).@"enum".fields.len]c.Model = undefined;
var buildBoxes: [@typeInfo(Part).@"enum".fields.len]BuildBox = undefined;

const anti_zfighting = 0.001;

pub fn loadData(gpa: Allocator) !void {
    try misc.cwd("assets");
    try misc.cwd("models");
    inline for (@typeInfo(Part).@"enum".fields, 0..) |field, i| {
        assets[i] = c.LoadModel(field.name ++ ".glb");
    }
    try misc.cwd("..");
    try misc.cwd("buildboxes");
    inline for (@typeInfo(Part).@"enum".fields, 0..) |field, i| {
        var robot = Robot.load(field.name ++ ".bot", gpa) catch try Robot.init(gpa, 0);
        defer robot.deinit(gpa);
        buildBoxes[i] = try BuildBox.init(robot, gpa);
    }
    try misc.cwd("..");
    try misc.cwd("..");
}

pub fn unloadData(gpa: Allocator) void {
    inline for (@typeInfo(Part).@"enum".fields, 0..) |_, i| {
        c.UnloadModel(assets[i]);
        buildBoxes[i].deinit(gpa);
    }
}

pub const Part = enum {
    cube,
    inner,
    prism,
    tetra,

    pub fn mesh(part: Part) c.Mesh {
        const i: usize = @intFromEnum(part);
        return assets[i].meshes[0];
    }

    pub fn buildBox(part: Part) BuildBox {
        const i: usize = @intFromEnum(part);
        return buildBoxes[i];
    }

    pub fn blueprint(part: Part) void {
        const offset = c.toVector3(@splat(0));
        const i: usize = @intFromEnum(part);
        assets[i].transform = Placement.zero.mat();
        c.DrawModel(assets[i], offset, BuildBox.scale + anti_zfighting, c.ColorAlpha(c.SKYBLUE, 0.25));
    }

    pub fn render(part: Part, placement: Placement, color: c.Color, preview: bool) void {
        const offset = c.toVector3(@splat(0));
        const i: usize = @intFromEnum(part);
        assets[i].transform = placement.mat();
        const mirrored = placement.rotation.mirrored();
        if (mirrored) c.rlSetCullFace(c.RL_CULL_FACE_FRONT);
        defer if (mirrored) c.rlSetCullFace(c.RL_CULL_FACE_BACK);
        if (preview)
            c.DrawModel(assets[i], offset, 1 + anti_zfighting, c.ColorAlpha(color, 0.25))
        else
            c.DrawModel(assets[i], offset, 1, color);
    }

    pub inline fn connections(part: Part) []const Placement {
        return switch (part) {
            .cube, .inner => &([_]Placement{
                .{
                    .position = .{ 0, 0, 0 },
                    .rotation = Placement.Rotation.down,
                },
                .{
                    .position = .{ 0, 0, 0 },
                    .rotation = Placement.Rotation.left,
                },
                .{
                    .position = .{ 0, 0, 0 },
                    .rotation = Placement.Rotation.front,
                },
                .{
                    .position = .{ 0, 0, 0 },
                    .rotation = Placement.Rotation.right,
                },
                .{
                    .position = .{ 0, 0, 0 },
                    .rotation = Placement.Rotation.back,
                },
                .{
                    .position = .{ 0, 0, 0 },
                    .rotation = Placement.Rotation.up,
                },
            }),
            .prism => &([_]Placement{
                .{
                    .position = .{ 0, 0, 0 },
                    .rotation = Placement.Rotation.down,
                },
                .{
                    .position = .{ 0, 0, 0 },
                    .rotation = Placement.Rotation.left,
                },
                .{
                    .position = .{ 0, 0, 0 },
                    .rotation = Placement.Rotation.back,
                },
                .{
                    .position = .{ 0, 0, 0 },
                    .rotation = Placement.Rotation.right,
                },
            }),
            .tetra => &([_]Placement{
                .{
                    .position = .{ 0, 0, 0 },
                    .rotation = Placement.Rotation.down,
                },
                .{
                    .position = .{ 0, 0, 0 },
                    .rotation = Placement.Rotation.left,
                },
                .{
                    .position = .{ 0, 0, 0 },
                    .rotation = Placement.Rotation.back,
                },
            }),
        };
    }
};
