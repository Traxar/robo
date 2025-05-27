const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @import("c.zig");
const Bind = @import("bind.zig").Bind;
const Options = @import("options.zig").Options;
const Editor = @import("editor.zig").Editor;
const Menu = @import("menu.zig").Menu;

const Mode = enum {
    close,
    edit,
};

pub const State = struct {
    allocator: Allocator,
    options: Options = .{},
    mode: Mode = .edit,
    editor: Editor,
    menu: Menu = .{},

    pub fn init(gpa: Allocator) !State {
        var state = State{
            .allocator = gpa,
            .editor = try Editor.init(gpa, 2000),
        };
        state.editor.camera = .{ .position = .{ 10, 10, 10 } };
        state.editor.camera.target(.{ 0, 0, 0 });
        return state;
    }

    pub fn deinit(self: *State) void {
        self.editor.deinit();
    }

    pub fn run(self: *State) !bool {
        if (c.WindowShouldClose()) return false;
        if (Bind.esc.pressed()) {
            self.menu.enabled = !self.menu.enabled;
        }
        if (!self.menu.enabled) {
            switch (self.mode) {
                .close => {
                    return false;
                },
                .edit => {
                    try self.editor.update(self.options.editor);
                },
            }
        }
        self.render();
        return true;
    }

    fn render(self: *State) void {
        c.BeginDrawing();
        defer c.EndDrawing();
        c.ClearBackground(c.RAYWHITE);

        switch (self.mode) {
            .close => {},
            .edit => {
                self.editor.render(self.options.editor);
            },
        }
        c.DrawFPS(10, 10);
        Menu.show(self);
    }
};
