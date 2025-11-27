const std = @import("std");
const Allocator = std.mem.Allocator;
const d = @import("c.zig");
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
    editor: Editor = undefined,
    menu: Menu = .{},
    frame_start: i128 = 0,

    pub fn init(gpa: Allocator) !State {
        var state = State{
            .allocator = gpa,
        };
        state.editor = try Editor.init(gpa, 2000);
        errdefer state.editor.deinit();
        state.editor.camera = .{ .position = .{ 10, 10, 10 } };
        state.editor.camera.target(.{ 0, 0, 0 });
        return state;
    }

    pub fn deinit(state: *State) void {
        state.editor.deinit();
    }

    pub fn run(state: *State) !bool {
        state.frame_start = std.time.nanoTimestamp();
        if (d.Window.shouldClose()) return false;
        if (d.Input.Digital.Key.escape.pressed()) {
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
        d.Window.Draw.begin();
        defer d.Window.Draw.end();
        d.Window.Draw.clear(.raywhite);

        switch (state.mode) {
            .close => {},
            .edit => {
                state.editor.render();
            },
        }
        Menu.show(state);

        if (state.options.show_fps) {
            var text_buffer: [32]u8 = @splat(' ');
            const frame_time = @as(f32, @floatFromInt(std.time.nanoTimestamp() -% state.frame_start)) * 1.0e-9;
            const fps_text = std.fmt.bufPrintZ(
                text_buffer[0..],
                "FPS: {} ({})",
                .{
                    d.Fps.get(),
                    @as(i32, @intFromFloat(@floor(1.0 / frame_time))),
                },
            ) catch return;
            d.Window.Draw.text(fps_text.ptr, 10, 10, 20, .green);
        }
    }
};
