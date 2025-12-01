const std = @import("std");
const Allocator = std.mem.Allocator;
const o = @import("o.zig");
const Placement = @import("placement.zig").Placement;
const Robot = @import("robot.zig").Type(.{ .mark_collisions = false });
const BuildBox = @import("buildbox.zig").BuildBox;
const misc = @import("misc.zig");
const renderer = @import("renderer.zig");

var models: [@typeInfo(Part).@"enum".fields.len]o.Model = undefined;
var model_bounds: [@typeInfo(Part).@"enum".fields.len]o.Box = undefined;
var buildBoxes: [@typeInfo(Part).@"enum".fields.len]BuildBox = undefined;

const anti_zfighting = 0.001;

pub fn loadData(gpa: Allocator) !void {
    try misc.cwd("assets");
    try misc.cwd("models");
    inline for (@typeInfo(Part).@"enum".fields, 0..) |field, i| {
        models[i] = .load(field.name ++ ".obj");
        model_bounds[i] = models[i].bounds();
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
        models[i].unload();
        buildBoxes[i].deinit(gpa);
    }
}

pub const Part = enum {
    cube,
    inner,
    prism,
    prism_concave,
    tetra,

    fn meshes(part: Part) []o.Mesh {
        const m = part.model();
        return @ptrCast(m.internal.meshes[0..@intCast(m.internal.meshCount)]);
    }

    fn model(part: Part) o.Model {
        const i: usize = @intFromEnum(part);
        return models[i];
    }

    fn modelBounds(part: Part) o.Box {
        const i: usize = @intFromEnum(part);
        return model_bounds[i];
    }

    pub fn buildBox(part: Part) BuildBox {
        const i: usize = @intFromEnum(part);
        return buildBoxes[i];
    }

    pub fn rayCollision(part: Part, placement: Placement, ray: o.Ray) ?o.Ray.Hit {
        const inv = placement.inv().transform(1);
        const ray_inv = o.Ray{
            .pos = inv.apply(ray.pos),
            .dir = inv.rotate(ray.dir),
        };
        var res: ?o.Ray.Hit = null;
        if (ray_inv.box(part.modelBounds())) |_| {
            for (part.meshes()) |mesh| {
                if (ray_inv.mesh(mesh)) |hit| {
                    if (res == null or hit.dist < res.?.dist)
                        res = hit;
                }
            }
        }
        return res;
    }

    pub fn blueprint(part: Part) void {
        const i: usize = @intFromEnum(part);
        const scale = BuildBox.scale * (1.0 + anti_zfighting);

        renderer.addToBuffer(
            models[i],
            o.Color.lightblue.fade(0.25),
            .{
                .pos = @splat(0),
                .rot = .diag(@splat(scale)),
            },
        );
    }

    pub const RenderOptions = struct {
        pub const Mode = enum { default, buildbox };
        preview: bool = false,
        mode: Mode = .buildbox,
    };

    pub fn render(part: Part, placement: Placement, color: o.Color, options: RenderOptions) void {
        const color_ = if (options.preview) color.fade(0.25) else color;
        const scale = @as(f32, if (options.preview) 1.0 + anti_zfighting else 1.0) *
            @as(f32, switch (options.mode) {
                .default => 1.0,
                .buildbox => 1.0 / @as(comptime_float, BuildBox.scale),
            });
        const scale_mat = o.Matrix.diag(@splat(scale));
        switch (options.mode) {
            .default => {
                const model_ = part.model();
                var transform = placement.transform(1);
                transform.rot = transform.rot.mul(scale_mat);
                renderer.addToBuffer(model_, color_, transform);
            },
            .buildbox => {
                const mat_part = placement.transform(1);
                const model_ = Part.cube.model();
                const bb = part.buildBox();
                var iter = bb.bounds.min;
                while (true) : (if (!bb.bounds.next(&iter)) break) {
                    if (bb.at(iter)) {
                        var transform = mat_part.add((Placement{ .position = iter, .rotation = .none }).transform(scale));
                        transform.rot = transform.rot.mul(scale_mat);
                        renderer.addToBuffer(model_, color_, transform);
                    }
                }
            },
        }
    }

    pub inline fn connections(part: Part) []const Placement {
        return switch (part) {
            .cube,
            .inner,
            => &([_]Placement{
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
            .prism,
            .prism_concave,
            => &([_]Placement{
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
