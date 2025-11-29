const c = @import("c.zig").c;
const convert = @import("convert.zig");
const state = @import("state.zig");

const Camera = @import("camera.zig");

pub fn begin(camera: Camera) void { //todo check for window
    state.begin(.render);
    c.BeginMode3D(convert.camera(camera));
}

pub fn end() void {
    c.EndMode3D();
    state.end(.render);
}
