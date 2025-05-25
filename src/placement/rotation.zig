const expect = @import("std").testing.expect;
const Shuffle = @import("shuffle.zig").Shuffle;
const Flip = @import("flip.zig").Flip;

pub const Rotation = packed struct {
    shuffle: Shuffle,
    flip: Flip,

    pub const none = Rotation{ .shuffle = .xyz, .flip = .ppp };
    pub const x90 = Rotation{ .shuffle = .xzy, .flip = .pnp };
    pub const x180 = x90.rotate(x90);
    pub const x270 = x180.rotate(x90);
    pub const y90 = Rotation{ .shuffle = .zyx, .flip = .ppn };
    pub const y180 = y90.rotate(y90);
    pub const y270 = y180.rotate(y90);
    pub const z90 = Rotation{ .shuffle = .yxz, .flip = .npp };
    pub const z180 = z90.rotate(z90);
    pub const z270 = z180.rotate(z90);
    pub const mirror = Rotation{ .shuffle = .xyz, .flip = .npp };
    pub const down = none;
    pub const front = x90;
    pub const up = y180;
    pub const right = y270;
    pub const left = y90;
    pub const back = x270;

    pub fn mirrored(a: Rotation) bool {
        return a.flip.mirrored() != a.shuffle.mirrored();
    }

    ///`shuffle` then `flip`
    pub fn apply(a: Rotation, T: type, v: @Vector(3, T)) @Vector(3, T) {
        return a.flip.apply(T, a.shuffle.apply(T, v));
    }

    ///```
    ///  a   b
    ///*-->*-->*
    ///```
    pub fn rotate(a: Rotation, b: Rotation) Rotation {
        return .{
            .shuffle = a.shuffle.shuffle(b.shuffle),
            .flip = b.flip.flip(a.flip.shuffle(b.shuffle)),
        };
    }

    pub fn inv(a: Rotation) Rotation {
        const s = a.shuffle.inv();
        return .{
            .shuffle = s,
            .flip = a.flip.shuffle(s),
        };
    }
};

test Rotation {
    //size
    try expect(@sizeOf(Rotation) == 1);

    const v = @Vector(3, i8){ 1, 2, 3 };
    const n = @typeInfo(Shuffle).@"enum".fields.len;
    const m = @typeInfo(Flip).@"enum".fields.len;

    //apply
    for (0..n) |i| {
        const s: Shuffle = @enumFromInt(i);
        for (0..m) |j| {
            const f: Flip = @enumFromInt(j);
            const r = Rotation{ .flip = f, .shuffle = s };

            const u = f.apply(i8, s.apply(i8, v));
            const u_ = r.apply(i8, v);
            try expect(@reduce(.And, u == u_));
        }
    }

    //rotate
    for (0..n) |i| {
        for (0..m) |j| {
            const a = Rotation{ .flip = @enumFromInt(j), .shuffle = @enumFromInt(i) };
            for (0..n) |k| {
                for (0..m) |l| {
                    const b = Rotation{ .flip = @enumFromInt(l), .shuffle = @enumFromInt(k) };
                    const c = b.apply(i8, a.apply(i8, v));
                    const c_ = a.rotate(b).apply(i8, v);
                    try expect(@reduce(.And, c == c_));
                }
            }
        }
    }

    //inverse
    for (0..n) |i| {
        const s: Shuffle = @enumFromInt(i);
        for (0..m) |j| {
            const f: Flip = @enumFromInt(j);
            const r = Rotation{ .flip = f, .shuffle = s };
            var id = r.rotate(r.inv());
            try expect(id == Rotation.none);
            id = r.inv().rotate(r);
            try expect(id == Rotation.none);
        }
    }
}

test {
    const r = Rotation.x90.rotate(Rotation.z90);
    try expect(r.shuffle == .zxy);
    try expect(r.flip == .ppp);
}
