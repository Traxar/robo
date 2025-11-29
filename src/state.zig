const std = @import("std");
const Allocator = std.mem.Allocator;
const o = @import("o.zig");
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
    options: Options = .{},
    mode: Mode = .edit,
    editor: Editor = undefined,
    menu: Menu = .{},

    pub fn init(gpa: Allocator) !State {
        var state = State{};
        state.editor = try Editor.init(gpa, 2000);
        errdefer state.editor.deinit();
        state.editor.camera = .{
            .position = .{ 10, 10, 10 },
            .rotation = undefined,
        };
        state.editor.camera.target(.{ 0, 0, 0 });
        return state;
    }

    pub fn deinit(state: *State) void {
        state.editor.deinit();
    }

    pub fn run(state: *State) !bool {
        if (o.Input.Digital.Key.escape.pressed()) {
            state.menu.enabled = !state.menu.enabled;
        }
        if (!state.menu.enabled) {
            switch (state.mode) {
                .close => {
                    return false;
                },
                .edit => {
                    try state.editor.update(o.window.frame.dt, state.options.editor);
                },
            }
        }
        state.render();
        return true;
    }

    fn render(state: *State) void {
        o.draw.begin();
        defer o.draw.end();
        o.draw.clear(.gray);
        switch (state.mode) {
            .close => {},
            .edit => {
                state.editor.render();
            },
        }
        Menu.show(state);

        if (state.options.show_fps) {
            var text_buffer: [1024]u8 = @splat(' ');
            const fps_text = std.fmt.bufPrintZ(
                text_buffer[0..],
                "FPS: {} ({})",
                .{
                    @round(1 / o.window.frame.dt),
                    @round(1 / o.window.frame.min_dt),
                },
            ) catch return;
            o.draw.text(fps_text.ptr, 10, 10, 20, .orange);
        }
    }
};
