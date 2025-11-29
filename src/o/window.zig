const c = @import("c.zig").c;
const convert = @import("convert.zig");
const state = @import("state.zig");

const Color = @import("color.zig");
const Monitor = @import("monitor.zig");
const Frame = @import("frame.zig").Type(f32);
const Draw = @import("draw.zig");

pub var frame: Frame = undefined;

pub fn begin(width_: usize, height_: usize, title: [*c]const u8) void {
    state.begin(.window);
    c.InitWindow(@intCast(width_), @intCast(height_), title);
    c.SetExitKey(c.KEY_NULL);
    frame = .init(@floatFromInt(monitor().rate()));
}

pub fn end() void {
    c.CloseWindow();
    state.end(.window);
}

pub fn shouldClose() bool {
    state.is(.window);
    return c.WindowShouldClose();
}

pub fn mousePosition() @Vector(2, f32) {
    state.is(.window);
    const a = c.GetMousePosition();
    return .{ a.x, a.y };
}

pub fn monitor() Monitor {
    state.is(.window);
    return Monitor{ .id = c.GetCurrentMonitor() };
}

pub fn size() @Vector(2, usize) {
    state.is(.window);
    return @intCast(@Vector(2, c_int){
        c.GetScreenWidth(),
        c.GetScreenHeight(),
    });
}
