const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @import("c.zig");
const misc = @import("misc.zig");
const Placement = @import("placement.zig").Placement;
const Robot = @import("robot.zig").Type(.{ .mark_collisions = false });
const BuildBox = @import("buildbox.zig").BuildBox;

var assets: [@typeInfo(Part).@"enum".fields.len]c.Model = undefined;
var buildBoxes: [@typeInfo(Part).@"enum".fields.len]BuildBox = undefined;

pub fn loadAssets(gpa: Allocator) !void {
    const application_directory = c.GetApplicationDirectory();
    _ = c.ChangeDirectory(application_directory);
    _ = c.ChangeDirectory("../../assets/");
    inline for (@typeInfo(Part).@"enum".fields, 0..) |field, i| {
        assets[i] = c.LoadModel("models/" ++ field.name ++ ".glb");
        var robot = Robot.load("buildboxes/" ++ field.name ++ ".bot", gpa) catch try Robot.init(gpa, 0);
        defer robot.deinit(gpa);
        buildBoxes[i] = try BuildBox.init(robot, gpa);
    }
    _ = c.ChangeDirectory(application_directory);
}

pub fn unloadAssets(gpa: Allocator) void {
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
        c.DrawModel(assets[i], offset, BuildBox.scale + 0.001, c.ColorAlpha(c.SKYBLUE, 0.25));
    }

    pub fn render(part: Part, placement: Placement, color: c.Color, preview: bool) void {
        const offset = c.toVector3(@splat(0));
        const i: usize = @intFromEnum(part);
        assets[i].transform = placement.mat();
        const mirrored = placement.rotation.mirrored();
        if (mirrored) c.rlSetCullFace(c.RL_CULL_FACE_FRONT);
        defer if (mirrored) c.rlSetCullFace(c.RL_CULL_FACE_BACK);
        if (preview)
            c.DrawModel(assets[i], offset, 1.001, c.ColorAlpha(color, 0.25))
        else
            c.DrawModel(assets[i], offset, 1, color);
    }

    pub inline fn connections(part: Part) []const Placement {
        return switch (part) {
            .cube, .inner => misc.sliceFromArray([_]Placement{
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
            .prism => misc.sliceFromArray([_]Placement{
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
            .tetra => misc.sliceFromArray([_]Placement{
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
