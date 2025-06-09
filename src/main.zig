const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @import("c.zig");
const parts = @import("parts.zig");
const State = @import("state.zig").State;

var gpa = std.heap.DebugAllocator(.{}){};
const allocator = gpa.allocator();
var state: State = undefined;

pub fn main() !void {
    try init();
    defer deinit();
    while (try state.run()) {}
}

fn init() !void {
    c.InitWindow(1280, 720, "robo");
    c.SetExitKey(c.KEY_NULL);
    //c.DisableCursor();
    const monitor_id = c.GetCurrentMonitor();
    const monitor_refresh_rate = c.GetMonitorRefreshRate(monitor_id);
    c.SetTargetFPS(monitor_refresh_rate);

    try parts.loadData(allocator);

    state = try State.init(allocator);
}

fn deinit() void {
    state.deinit();
    parts.unloadData(allocator);
    if (gpa.deinit() == .leak) @panic("TEST FAIL");
    c.CloseWindow();
}
