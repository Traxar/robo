const Color = @This();

rgba: @Vector(4, u8),

pub const white = rgb(255, 255, 255);
pub const yellow = rgb(253, 249, 0);
pub const orange = rgb(255, 161, 0);
pub const red = rgb(230, 41, 55);
pub const purple = rgb(200, 122, 255);
pub const blue = rgb(0, 121, 241);
pub const lightblue = rgb(102, 191, 255);
pub const lime = rgb(0, 228, 48);
pub const green = rgb(0, 158, 47);
pub const beige = rgb(211, 176, 131);
pub const brown = rgb(127, 106, 79);
pub const black = rgb(0, 0, 0);
pub const gray = rgb(130, 130, 130);
pub const lightgray = rgb(200, 200, 200);

pub fn rgb(r: u8, g: u8, b: u8) Color {
    return .{ .rgba = .{ r, g, b, 255 } };
}

pub fn fade(color: Color, alpha_: f32) Color {
    var res = color;
    res.rgba[3] = @intFromFloat(@as(f32, @floatFromInt(res.rgba[3])) * alpha_);
    return res;
}
