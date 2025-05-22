const c = @import("c.zig");

pub const Options = struct {
    camera: @import("camera.zig").Camera.Options = .{},
};
