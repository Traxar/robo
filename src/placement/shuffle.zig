const expect = @import("std").testing.expect;

pub const Shuffle = enum(u3) {
    xyz,
    xzy,
    yxz,
    yzx,
    zxy,
    zyx,

    pub fn mask(a: Shuffle) @Vector(3, i32) {
        return switch (a) {
            .xyz => .{ 0, 1, 2 },
            .xzy => .{ 0, 2, 1 },
            .yxz => .{ 1, 0, 2 },
            .yzx => .{ 1, 2, 0 },
            .zxy => .{ 2, 0, 1 },
            .zyx => .{ 2, 1, 0 },
        };
    }

    pub fn mirrored(a: Shuffle) bool {
        return switch (a) {
            .xyz, .yzx, .zxy => false,
            .xzy, .yxz, .zyx => true,
        };
    }

    pub fn apply(a: Shuffle, T: type, v: @Vector(3, T)) @Vector(3, T) {
        return switch (a) {
            inline else => |a_| @shuffle(T, v, undefined, mask(a_)),
        };
    }

    ///```
    ///  a   b
    ///*-->*-->*
    /// ```
    pub fn shuffle(a: Shuffle, b: Shuffle) Shuffle {
        const lookup = comptime _: {
            const n = @typeInfo(Shuffle).@"enum".fields.len;
            var lookup: [n][n]Shuffle = undefined;
            for (0..n) |i| {
                const c: Shuffle = @enumFromInt(i);
                for (0..n) |j| {
                    const res = c.apply(i32, mask(@enumFromInt(j)));
                    for (0..n) |k| {
                        if (@reduce(.And, mask(@enumFromInt(k)) == res)) {
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

    pub fn inv(a: Shuffle) Shuffle {
        return switch (a) {
            .yzx => .zxy,
            .zxy => .yzx,
            else => a,
        };
    }
};

test Shuffle {
    try expect(Shuffle.xyz.shuffle(.xzy) == .xzy);
    try expect(Shuffle.zxy.shuffle(.xzy) == .zyx);
    try expect(Shuffle.yxz.shuffle(.xzy) == .yzx);
}
