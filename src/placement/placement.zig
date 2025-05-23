const expect = @import("std").testing.expect;
const misc = @import("../misc.zig");
const c = @import("../c.zig");

pub fn PlacementType(T: type) type {
    return packed struct {
        const Placement = @This();
        pub const Position = @Vector(3, T);
        pub const Rotation = @import("rotation.zig").Rotation;
        position: Position, //x,y,z
        rotation: Rotation, //shuffle and flip

        pub const zero: Placement = .{
            .position = @splat(0),
            .rotation = Rotation.none,
        };

        ///```
        ///  a   b
        ///*-->*-->*
        ///```
        pub fn place(a: Placement, b: Placement) Placement {
            return .{
                .position = a.position + a.rotation.apply(T, b.position),
                .rotation = b.rotation.rotate(a.rotation),
            };
        }

        ///```
        ///  a   b
        ///*-->*-->*
        ///```
        pub fn move(a: Placement, b: Position) Placement {
            return .{
                .position = a.position + a.rotation.apply(T, b),
                .rotation = a.rotation,
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

        pub fn mat(a: Placement) c.Matrix {
            var res = c.Matrix{}; //zeros
            const rot = a.rotation.inv();
            switch (rot.shuffle.mask()[0]) {
                0 => res.m0 = rot.flip.mask(f32)[0],
                1 => res.m1 = rot.flip.mask(f32)[0],
                2 => res.m2 = rot.flip.mask(f32)[0],
                else => unreachable,
            }
            switch (rot.shuffle.mask()[1]) {
                0 => res.m4 = rot.flip.mask(f32)[1],
                1 => res.m5 = rot.flip.mask(f32)[1],
                2 => res.m6 = rot.flip.mask(f32)[1],
                else => unreachable,
            }
            switch (rot.shuffle.mask()[2]) {
                0 => res.m8 = rot.flip.mask(f32)[2],
                1 => res.m9 = rot.flip.mask(f32)[2],
                2 => res.m10 = rot.flip.mask(f32)[2],
                else => unreachable,
            }
            switch (@typeInfo(T)) {
                .int => {
                    res.m12 = @floatFromInt(a.position[0]);
                    res.m13 = @floatFromInt(a.position[1]);
                    res.m14 = @floatFromInt(a.position[2]);
                },
                .float => {
                    res.m12 = @floatCast(a.position[0]);
                    res.m13 = @floatCast(a.position[1]);
                    res.m14 = @floatCast(a.position[2]);
                },
                else => @compileError("unexpected type"),
            }
            res.m15 = 1;
            return res;
        }

        /// return rayCollision of a connection at placement
        pub fn rayCollision(placement: Placement, ray: c.Ray) c.RayCollision {
            const miss = c.RayCollision{};
            const eps = 1e-8;
            const inv_matrix = placement.inv().mat();
            const dir = c.Vector3Rotate(ray.direction, inv_matrix);
            if (dir.z <= eps) return miss; //ray looks in wrong direction
            const pos = c.Vector3Transform(ray.position, inv_matrix);
            if (pos.z >= -0.5) return miss; //ray starts at wrong side

            //                        -0.5   1       0
            // solve: pos + dir * t = -0.5 + 0 * x + 1 * y
            //                        -0.5   0       0
            // for: t, x, y
            const t = -(0.5 + pos.z) / dir.z;
            const x = 0.5 + pos.x + dir.x * t;
            if (x <= 0 or x >= 1) return miss;
            const y = 0.5 + pos.y + dir.y * t;
            if (y <= 0 or y >= 1) return miss;
            const matrix = placement.mat();
            return c.RayCollision{
                .hit = true,
                .distance = t,
                .normal = c.Vector3Rotate(c.toVec3(.{ 0, 0, -1 }), matrix),
                .point = c.Vector3Transform(c.toVec3(.{ x - 0.5, y - 0.5, -0.5 }), matrix),
            };
        }
    };
}

test "Placement" {
    const Placement = PlacementType(i8);
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
    const c__ = a.place(b);
    try expect(@reduce(.And, c_.position == c__.position));
    try expect(c_.rotation == c__.rotation);

    //inverse
    const d = Placement{
        .position = .{ -33, 8, 21 },
        .rotation = .{ .shuffle = .zxy, .flip = .pnn },
    };
    const d_ = c_.inv();
    try expect(@reduce(.And, d.position == d_.position));
    try expect(d.rotation == d_.rotation);
}
