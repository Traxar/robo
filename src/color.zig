const c = @import("c.zig").c;

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

    pub const collision = c.MAROON;

    pub fn raylib(color: Color) c.Color {
        return switch (color) {
            .white => c.RAYWHITE,
            .yellow => c.YELLOW,
            .orange => c.ORANGE,
            .red => c.RED,
            .purple => c.PURPLE,
            .blue => c.BLUE,
            .lightblue => c.SKYBLUE,
            .lime => c.LIME,
            .green => c.GREEN,
            .beige => c.BEIGE,
            .brown => c.BROWN,
            .black => c.Color{ .a = 255, .r = 10, .g = 10, .b = 10 },
            .gray => c.GRAY,
            .lightgray => c.LIGHTGRAY,
        };
    }
};
