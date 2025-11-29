const c = @import("c.zig").c;
const convert = @import("convert.zig");
const state = @import("state.zig");

const Color = @import("color.zig");
const window = @import("window.zig");
const Frame = @import("frame.zig");
const Camera = @import("camera.zig");
const Rect = @import("rect.zig");

pub fn begin() void {
    state.begin(.draw);
    c.BeginDrawing();
}

pub fn end() void {
    c.EndDrawing();
    state.end(.draw);
    Frame.wait(&window.frame);
}

pub fn size() @Vector(2, f32) {
    state.is(.draw);
    return @floatFromInt(@Vector(2, c_int){
        c.GetRenderWidth(),
        c.GetRenderHeight(),
    });
}

pub fn clear(
    color: Color,
) void {
    state.is(.draw);
    c.ClearBackground(convert.color(color));
}

pub fn rect(
    rect_: Rect,
    color: Color,
) void {
    state.is(.draw);
    c.DrawRectangleV(
        convert.vector(rect_.min),
        convert.vector(rect_.max - rect_.min),
        convert.color(color),
    );
}

pub fn text(
    text_: [*c]const u8,
    posX: f32,
    posY: f32,
    fontSize: f32,
    color: Color,
) void {
    state.is(.draw);
    c.DrawText(
        text_,
        @intFromFloat(posX),
        @intFromFloat(posY),
        @intFromFloat(fontSize),
        convert.color(color),
    );
}
