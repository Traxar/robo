const std = @import("std");
const c = @import("c.zig");
const parts = @import("parts.zig");
const Bind = @import("bind.zig").Bind;
const Options = @import("options.zig").Options;
const Editor = @import("editor.zig").Editor;
const Mode = @import("mode.zig").Mode;
const Menu = @import("menu.zig").Menu;

var gpa = std.heap.DebugAllocator(.{}){};
var allocator = gpa.allocator();

var options: Options = .{};
var mode: Mode = .edit;
var editor: Editor = undefined;
var menu: Menu = .{};

pub fn main() !void {
    try init();
    defer deinit();

    //main loop
    while (!c.WindowShouldClose()) {
        if (Bind.esc.pressed()) {
            menu.enabled = !menu.enabled;
        }
        if (!menu.enabled) {
            switch (mode) {
                .close => {
                    break;
                },
                .edit => {
                    try editor.update(options.editor);
                },
            }
        }
        render();
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

    editor = try Editor.init(allocator, 2000);
    editor.camera = .{ .position = .{ 10, 10, 10 } };
    editor.camera.target(.{ 0, 0, 0 });
}

fn deinit() void {
    editor.deinit();
    if (gpa.deinit() == .leak) @panic("TEST FAIL");
    c.CloseWindow();
}

fn render() void {
    c.BeginDrawing();
    defer c.EndDrawing();
    c.ClearBackground(c.RAYWHITE);

    switch (mode) {
        .close => {},
        .edit => {
            editor.render(options.editor);
        },
    }

    c.DrawFPS(10, 10);

    menu.show(&options, &mode);
}
