const o = @import("o.zig");

pub const Color = enum {
    white,
    yellow,
    orange,
    red,
    purple,
    blue,
    lightblue,
    lime,
    green,
    beige,
    brown,
    black,
    gray,
    lightgray,

    pub const collision: o.Color = .rgb(190, 33, 55);

    pub fn rgba(color: Color) o.Color {
        return switch (color) {
            .white => .rgb(245, 245, 245),
            .black => .rgb(10, 10, 10),
            inline else => |col| @field(o.Color, @tagName(col)),
        };
    }
};
