const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @import("c.zig");
const Placement = @import("placement.zig").Placement;
const Robot = @import("robot.zig").Type(.{ .mark_collisions = false });
const BuildBox = @import("buildbox.zig").BuildBox;
const misc = @import("misc.zig");
const Renderer = @import("renderer.zig");

var models: [@typeInfo(Part).@"enum".fields.len]c.Model = undefined;
var model_bounds: [@typeInfo(Part).@"enum".fields.len]c.BoundingBox = undefined;
var buildBoxes: [@typeInfo(Part).@"enum".fields.len]BuildBox = undefined;
var shader: c.Shader = undefined;

const anti_zfighting = 0.001;

pub fn loadData(gpa: Allocator) !void {
    shader = c.LoadShaderFromMemory(
        @embedFile("shaders/instanced.vert.glsl"),
        @embedFile("shaders/instanced.frag.glsl"),
    );
    c.rlDisableBackfaceCulling(); //?workaround as shader does not (yet) support flipped placements
    shader.locs[c.SHADER_LOC_MATRIX_MVP] = c.GetShaderLocation(shader, "mvp");

    try misc.cwd("assets");
    try misc.cwd("models");
    inline for (@typeInfo(Part).@"enum".fields, 0..) |field, i| {
        models[i] = c.LoadModel(field.name ++ ".obj");
        for (0..@intCast(models[i].materialCount)) |j| {
            models[i].materials[j].shader = shader;
        }
        model_bounds[i] = c.GetModelBoundingBox(models[i]);
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
        c.UnloadModel(models[i]);
        buildBoxes[i].deinit(gpa);
    }
    c.UnloadShader(shader);
}

pub const Part = enum {
    cube,
    inner,
    prism,
    prism_concave,
    tetra,

    fn meshes(part: Part) []c.Mesh {
        const m = part.model();
        return m.meshes[0..@intCast(m.meshCount)];
    }

    fn model(part: Part) c.Model {
        const i: usize = @intFromEnum(part);
        return models[i];
    }

    fn modelBounds(part: Part) c.BoundingBox {
        const i: usize = @intFromEnum(part);
        return model_bounds[i];
    }

    pub fn buildBox(part: Part) BuildBox {
        const i: usize = @intFromEnum(part);
        return buildBoxes[i];
    }

    pub fn rayCollision(part: Part, placement: Placement, ray: c.Ray) c.RayCollision {
        const inv = placement.inv().mat(1);
        const ray_ = c.Ray{ .position = c.Vector3Transform(ray.position, inv), .direction = c.Vector3Rotate(ray.direction, inv) };
        var res = c.RayCollision{ .hit = false };
        if (c.GetRayCollisionBox(ray_, part.modelBounds()).hit) {
            for (part.meshes()) |mesh| {
                const r = c.GetRayCollisionMesh(ray_, mesh, comptime c.MatrixIdentity());
                if (r.hit and (!res.hit or r.distance < res.distance))
                    res = r;
            }
        }
        return res;
    }

    pub fn blueprint(part: Part) void {
        const offset = c.toVector3(@splat(0));
        const i: usize = @intFromEnum(part);
        const scale = BuildBox.scale + anti_zfighting;
        models[i].transform = (Placement{}).mat(1.0 / scale);
        c.DrawModel(models[i], offset, scale, c.ColorAlpha(c.SKYBLUE, 0.25));
    }

    pub const RenderOptions = struct {
        pub const Mode = enum { default, buildbox };
        preview: bool = false,
        mode: Mode = .buildbox,
    };

    pub fn render(part: Part, placement: Placement, color: c.Color, options: RenderOptions) void {
        const color_ = if (options.preview) c.ColorAlpha(color, 0.25) else color;
        const scale = @as(f32, if (options.preview) 1.0 + anti_zfighting else 1.0) *
            @as(f32, switch (options.mode) {
                .default => 1.0,
                .buildbox => 1.0 / @as(comptime_float, BuildBox.scale),
            });
        const scale_mat = c.MatrixScale(scale, scale, scale);
        switch (options.mode) {
            .default => {
                const model_ = part.model();
                const transform = c.MatrixMultiply(scale_mat, placement.mat(1));
                Renderer.addToBuffer(model_, color_, transform);
            },
            .buildbox => {
                const mat_part = placement.mat(1);
                const model_ = Part.cube.model();
                const bb = part.buildBox();
                var iter = bb.bounds.min;
                while (true) : (if (!bb.bounds.next(&iter)) break) {
                    if (bb.at(iter)) {
                        const transform = c.MatrixMultiply(scale_mat, c.MatrixMultiply(
                            (Placement{ .position = iter, .rotation = .none }).mat(scale),
                            mat_part,
                        ));
                        Renderer.addToBuffer(model_, color_, transform);
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
