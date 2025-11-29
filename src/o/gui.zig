const c = @import("c.zig").c;
const convert = @import("convert.zig");
const state = @import("state.zig");

const Rect = @import("rect.zig");

pub fn button(rect: Rect, text: [*c]const u8) bool {
    state.is(.draw);
    return c.GuiButton(convert.rect(rect), text) == 1;
}

pub fn panel(rect: Rect, text: [*c]const u8) void {
    state.is(.draw);
    _ = c.GuiPanel(convert.rect(rect), text);
}

pub fn enable() void {
    state.is(.draw);
    c.GuiEnable();
}

pub fn disable() void {
    state.is(.draw);
    c.GuiDisable();
}
