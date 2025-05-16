const c = @import("c.zig");
const misc = @import("misc.zig");
const Placement = @import("placement.zig").Placement;

var assets: [@typeInfo(Part).@"enum".fields.len]c.Model = undefined;

pub fn loadAssets() void {
    const application_directory = c.GetApplicationDirectory();
    _ = c.ChangeDirectory(application_directory);
    _ = c.ChangeDirectory("../../assets/");
    inline for (@typeInfo(Part).@"enum".fields, 0..) |field, i| {
        assets[i] = c.LoadModel(field.name ++ ".glb");
    }
}

pub const Part = enum {
    cube,
    //tetra,
    cone,

    pub fn mesh(part: Part) c.Mesh {
        const i: usize = @intFromEnum(part);
        return assets[i].meshes[0];
    }

    pub fn render(part: Part, placement: Placement, color: c.Color, preview: bool) void {
        const i: usize = @intFromEnum(part);
        assets[i].transform = placement.mat();
        if (preview)
            c.DrawModelWires(assets[i], misc.vec(0, 0, 0), 1, color)
        else
            c.DrawModel(assets[i], misc.vec(0, 0, 0), 1, color);
    }

    pub inline fn connections(part: Part) []const Placement {
        return switch (part) {
            .cube => misc.sliceFromArray([_]Placement{
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
            // .tetra => misc.sliceFromArray([_]Placement{
            //     .{
            //         .position = .{ 0, 0, 0 },
            //         .rotation = Placement.Rotation.down,
            //     },
            //     .{
            //         .position = .{ 0, 0, 0 },
            //         .rotation = Placement.Rotation.left,
            //     },
            //     .{
            //         .position = .{ 0, 0, 0 },
            //         .rotation = Placement.Rotation.back,
            //     },
            // }),
            .cone => misc.sliceFromArray([_]Placement{
                .{
                    .position = .{ 0, 0, 0 },
                    .rotation = Placement.Rotation.down,
                },
            }),
        };
    }
};
