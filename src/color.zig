const c = @import("c.zig");

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

    pub const collision = c.Color.maroon;

    pub fn rgba(color: Color) c.Color {
        return switch (color) {
            .white => .raywhite,
            .black => c.Color{ .r = 10, .g = 10, .b = 10 },
            inline else => |col| @field(c.Color, @tagName(col)),
        };
    }
};
