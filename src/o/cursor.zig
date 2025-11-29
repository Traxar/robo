const c = @import("c.zig").c;

pub fn hidden() bool {
    return c.IsCursorHidden();
}

pub fn enable() void {
    c.EnableCursor();
}

pub fn disable() void {
    c.DisableCursor();
}
