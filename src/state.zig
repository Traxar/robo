const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @import("c.zig");
const Bind = @import("bind.zig").Bind;
const Editor = @import("editor.zig").Editor;
const Menu = @import("menu.zig").Menu;

const Mode = enum {
    close,
    edit,
};

pub const Options = struct {
    show_fps: bool = true,
    editor: @import("editor.zig").Editor.Options = .{},
};

pub const State = struct {
    allocator: Allocator,
    options: Options = .{},
    mode: Mode = .edit,
    editor: Editor,
    menu: Menu = .{},
    frame_start: i64 = 0,

    pub fn init(gpa: Allocator) !State {
        var state = State{
            .allocator = gpa,
            .editor = try Editor.init(gpa, 2000),
        };
        state.editor.camera = .{ .position = .{ 10, 10, 10 } };
        state.editor.camera.target(.{ 0, 0, 0 });
        return state;
    }

    pub fn deinit(state: *State) void {
        state.editor.deinit();
    }

    pub fn run(state: *State) !bool {
        state.frame_start = std.time.microTimestamp();
        if (c.WindowShouldClose()) return false;
        if (Bind.esc.pressed()) {
            state.menu.enabled = !state.menu.enabled;
        }
        if (!state.menu.enabled) {
            switch (state.mode) {
                .close => {
                    return false;
                },
                .edit => {
                    try state.editor.update(state.options.editor);
                },
            }
        }
        state.render();
        return true;
    }

    fn render(state: *State) void {
        c.BeginDrawing();
        defer c.EndDrawing();
        c.ClearBackground(c.RAYWHITE);

        switch (state.mode) {
            .close => {},
            .edit => {
                state.editor.render(state.options.editor);
            },
        }
        Menu.show(state);

        if (state.options.show_fps) {
            var text_buffer = (" " ** 20).*;
            const frame_time = @as(f32, @floatFromInt(@max(1, std.time.microTimestamp() - state.frame_start))) * 1.0e-6;
            const fps_text = std.fmt.bufPrint(text_buffer[0..], "FPS: {} ({})", .{ c.GetFPS(), @as(i32, @intFromFloat(@floor(1.0 / frame_time))) }) catch return;
            c.DrawText(fps_text.ptr, 10, 10, 20, c.LIME);
        }
    }
};
