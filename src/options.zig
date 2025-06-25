const c = @import("c.zig");

pub const Options = struct {
    show_fps: bool = true,
    editor: @import("editor.zig").Editor.Options = .{},
};
