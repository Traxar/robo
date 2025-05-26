const c = @import("c.zig");
const Bind = @This();
key: c_int = c.KEY_NULL, //c.KEY_...
mouse: ?c_int = null, //c.MOUSE_BUTTON_... scrolling has to be hardcoded for now

pub fn pressed(bind: Bind) bool {
    return c.IsKeyPressed(bind.key) or (bind.mouse != null and c.IsMouseButtonPressed(bind.mouse.?));
}

pub fn down(bind: Bind) bool {
    return c.IsKeyDown(bind.key) or (bind.mouse != null and c.IsMouseButtonDown(bind.mouse.?));
}

pub fn released(bind: Bind) bool {
    return c.IsKeyReleased(bind.key) or (bind.mouse != null and c.IsMouseButtonReleased(bind.mouse.?));
}
