const expect = @import("std").testing.expect;
const o = @import("../o.zig");

pub fn Type(T: type) type {
    return packed struct {
        const Placement = @This();
        pub const Position = @Vector(3, T);
        pub const Rotation = @import("rotation.zig").Rotation;
        pub const BoundingBox = @import("boundingbox.zig").Type(T);
        position: Position = @splat(0), //x,y,z
        rotation: Rotation = Rotation.none, //shuffle and flip

        pub const connection = Placement{
            .position = .{ 0, 0, -1 },
            .rotation = Placement.Rotation.up,
        };

        ///```
        ///  a   b
        ///*-->*-->*
        ///```
        pub fn place(a: Placement, b: Placement) !Placement {
            const pos, const overflow = @addWithOverflow(
                a.position,
                a.rotation.apply(T, b.position),
            );
            if (@reduce(.Or, overflow != @as(@Vector(3, u1), @splat(0))))
                return error.OutOfBounds;
            return .{
                .position = pos,
                .rotation = b.rotation.rotate(a.rotation),
            };
        }

        ///```
        ///  a   b
        ///*-->*-->*
        ///```
        pub fn placeSat(a: Placement, b: Placement) Placement {
            return .{
                .position = a.position +| a.rotation.apply(T, b.position),
                .rotation = b.rotation.rotate(a.rotation),
            };
        }

        ///```
        ///  a   b
        ///*-->*-->*
        ///```
        pub fn rotate(a: Placement, b: Rotation) Placement {
            return .{
                .position = a.position,
                .rotation = b.rotate(a.rotation),
            };
        }

        pub fn inv(a: Placement) Placement {
            const s = a.rotation.inv();
            return .{
                .position = s.apply(i8, -a.position),
                .rotation = s,
            };
        }

        pub fn transform(a: Placement, scale: f32) o.Transform {
            var res: o.Transform = .{
                .rot = .zero,
                .pos = undefined,
            };
            const rot = a.rotation.inv();
            for (0..3) |j| {
                const i: usize = @intCast(rot.shuffle.mask()[j]);
                res.rot.col[j][i] = rot.flip.mask(f32)[j];
            }
            res.pos = switch (@typeInfo(T)) {
                .int => @floatFromInt(a.position),
                .float => @floatCast(a.position),
                else => @compileError("unexpected type"),
            };
            res.pos *= @splat(scale);
            return res;
        }

        /// return rayCollision of a connection at `placement`
        pub fn rayCollision(placement: Placement, ray: o.Ray) ?o.Ray.Hit {
            const eps = 1e-8;
            const tr_inv = placement.inv().transform(1);
            const dir = tr_inv.rotate(ray.dir);
            if (dir[2] <= eps) return null; //ray looks in wrong direction
            const pos = tr_inv.apply(ray.pos);
            if (pos[2] >= -0.5) return null; //ray starts at wrong side

            //                        -0.5   1       0
            // solve: pos + dir * t = -0.5 + 0 * x + 1 * y
            //                        -0.5   0       0
            // for: t, x, y
            const t = -(0.5 + pos[2]) / dir[2];
            const x = 0.5 + pos[0] + dir[0] * t;
            if (x <= 0 or x >= 1) return null;
            const y = 0.5 + pos[1] + dir[1] * t;
            if (y <= 0 or y >= 1) return null;
            const tr = placement.transform(1);
            return .{
                .dist = t,
                .normal = tr.rotate(.{ 0, 0, -1 }),
            };
        }
    };
}

test "Placement" {
    const Placement = Type(i8);
    //size
    try expect(@sizeOf(Placement) == 4);

    //place
    const a = Placement{
        .position = .{ 10, 20, 30 },
        .rotation = Placement.Rotation.z90,
    };
    const b = Placement{
        .position = .{ 1, 2, 3 },
        .rotation = Placement.Rotation.y270,
    };
    const c_ = Placement{
        .position = .{ 10 - 2, 20 + 1, 30 + 3 },
        .rotation = .{ .shuffle = .yzx, .flip = .nnp },
    };
    const c__ = try a.place(b);
    try expect(@reduce(.And, c_.position == c__.position));
    try expect(c_.rotation == c__.rotation);

    //inverse
    const e = Placement{
        .position = .{ -33, 8, 21 },
        .rotation = .{ .shuffle = .zxy, .flip = .pnn },
    };
    const e_ = c_.inv();
    try expect(@reduce(.And, e.position == e_.position));
    try expect(e.rotation == e_.rotation);
}
