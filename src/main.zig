const std = @import("std");
const c = @import("c.zig");
const misc = @import("misc.zig");
const vec = misc.vec;
const parts = @import("parts.zig");
const Placement = @import("placement.zig").Placement;
const Robot = @import("robot.zig").Type(.{
    .mark_collisions = true,
});
const Camera = @import("camera.zig").Camera;
const Options = @import("options.zig").Options;
const Color = @import("color.zig").Color;
const Editor = @import("editor.zig").Editor;

var options: Options = .{};
var gpa = std.heap.DebugAllocator(.{}){};
var allocator = gpa.allocator();

const Mode = enum {
    edit,
};

var mode: Mode = .edit;
var editor: Editor = undefined;

pub fn main() !void {
    try init();
    defer deinit();

    //main loop
    while (!c.WindowShouldClose()) {
        switch (mode) {
            .edit => {
                try editor.update(options.editor);
                render();
            },
        }
    }
}

fn init() !void {
    c.InitWindow(1280, 720, "hello world");
    c.SetExitKey(c.KEY_NULL);
    //c.DisableCursor();
    const monitor_id = c.GetCurrentMonitor();
    const monitor_refresh_rate = c.GetMonitorRefreshRate(monitor_id);
    c.SetTargetFPS(monitor_refresh_rate);

    parts.loadAssets();

    editor = .{
        .camera = .{ .position = .{ 10, 10, 10 } },
        .robot = try Robot.init(allocator, 2000),
    };
    editor.camera.target(.{ 0, 0, 0 });
}

fn render() void {
    c.BeginDrawing();
    defer c.EndDrawing();
    c.ClearBackground(c.RAYWHITE);

    c.DrawFPS(10, 10);
    editor.render(options.editor);
}

fn deinit() void {
    editor.robot.deinit();
    if (gpa.deinit() == .leak) @panic("TEST FAIL");
    c.CloseWindow();
}
