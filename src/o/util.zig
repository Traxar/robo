const std = @import("std");
const builtin = @import("builtin");

pub fn panic(comptime format: []const u8, args: anytype) noreturn {
    switch (builtin.mode) {
        .Debug, .ReleaseSafe => std.debug.panic(format, args),
        .ReleaseFast, .ReleaseSmall => unreachable,
    }
}
