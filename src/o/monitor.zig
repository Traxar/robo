const c = @import("c.zig").c;

const Monitor = @This();
id: c_int,

pub fn rate(monitor: Monitor) usize {
    return @intCast(c.GetMonitorRefreshRate(monitor.id));
}

pub fn size(monitor: Monitor) @Vector(2, usize) {
    return @intCast(@Vector(2, c_int){
        c.GetMonitorWidth(monitor.id),
        c.GetMonitorHeight(monitor.id),
    });
}
