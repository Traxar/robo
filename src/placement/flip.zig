const expect = @import("std").testing.expect;
const Shuffle = @import("shuffle.zig").Shuffle;

pub const Flip = enum(u3) {
    ppp,
    ppn,
    pnp,
    pnn,
    npp,
    npn,
    nnp,
    nnn,

    pub fn mask(a: Flip, T: type) @Vector(3, T) {
        return switch (a) {
            .ppp => .{ 1, 1, 1 },
            .ppn => .{ 1, 1, -1 },
            .pnp => .{ 1, -1, 1 },
            .pnn => .{ 1, -1, -1 },
            .npp => .{ -1, 1, 1 },
            .npn => .{ -1, 1, -1 },
            .nnp => .{ -1, -1, 1 },
            .nnn => .{ -1, -1, -1 },
        };
    }

    pub fn mirrored(a: Flip) bool {
        return switch (a) {
            inline else => |a_| @reduce(.Mul, a_.mask(i8)) == -1,
        };
    }

    pub fn apply(a: Flip, T: type, v: @Vector(3, T)) @Vector(3, T) {
        return v * a.mask(T);
    }

    pub fn flip(a: Flip, b: Flip) Flip {
        return @enumFromInt(@intFromEnum(a) ^ @intFromEnum(b));
    }

    pub fn shuffle(a: Flip, b: Shuffle) Flip {
        const lookup = comptime _: {
            const n = @typeInfo(Shuffle).@"enum".fields.len;
            const m = @typeInfo(Flip).@"enum".fields.len;
            var lookup: [m][n]Flip = undefined;
            for (0..n) |i| {
                const c: Shuffle = @enumFromInt(i);
                for (0..m) |j| {
                    const res = c.apply(i32, mask(@enumFromInt(j), i32));
                    for (0..m) |k| {
                        if (@reduce(.And, mask(@enumFromInt(k), i32) == res)) {
                            lookup[j][i] = @enumFromInt(k);
                            break;
                        }
                    }
                }
            }
            break :_ lookup;
        };
        return lookup[@intFromEnum(a)][@intFromEnum(b)];
    }
};

test Flip {
    try expect(Flip.npp.shuffle(.xzy) == .npp);
    try expect(Flip.npp.shuffle(.zxy) == .pnp);
    try expect(Flip.npp.shuffle(.yzx) == .ppn);
}
