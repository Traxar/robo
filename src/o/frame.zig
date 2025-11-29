const std = @import("std");

fn now() u64 {
    return @truncate(@as(u128, @bitCast(std.time.nanoTimestamp())));
}

fn sleep(ns: u64) void {
    std.Thread.sleep(ns);
}

fn nsToS(F: type, ns: u64) F {
    return @as(f32, @floatFromInt(ns)) / std.time.ns_per_s;
}

pub fn Type(F: type) type {
    if (@typeInfo(F) != .float) @compileError("unexpected type");
    return struct {
        const Frame = @This();

        target_diff_ns: u64,
        prev_ns: u64,
        dt: F = 0,
        min_dt: F = 0,

        pub const inf = std.math.inf(comptime_float);

        pub fn init(target_fps: F) Frame {
            if (target_fps <= 0) unreachable;
            return .{
                .target_diff_ns = @intFromFloat(std.time.ns_per_s / target_fps),
                .prev_ns = now(),
            };
        }
    };
}

///internal
pub fn wait(frame_ptr: anytype) void {
    const F = @TypeOf(frame_ptr.dt);
    var curr_ns = now();
    defer frame_ptr.prev_ns = curr_ns;
    const diff_ns = curr_ns -% frame_ptr.prev_ns;
    frame_ptr.min_dt = nsToS(F, diff_ns);
    frame_ptr.dt = _: {
        const wait_ns = frame_ptr.target_diff_ns -| diff_ns;
        if (wait_ns > 0) {
            sleep(wait_ns);
            curr_ns = now();
            break :_ nsToS(F, curr_ns -% frame_ptr.prev_ns);
        } else {
            break :_ frame_ptr.min_dt;
        }
    };
}
