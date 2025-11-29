const Matrix = @import("matrix.zig").Type;

pub fn Type(n: usize, Element: type) type {
    return struct {
        const Transform = @This();

        rot: Matrix(n, Element),
        pos: @Vector(n, Element),

        pub const none: Transform = .{
            .rot = .diag(@splat(1)),
            .pos = @splat(0),
        };

        pub fn apply(transform: Transform, vec: @Vector(n, Element)) @Vector(n, Element) {
            return transform.rotate(vec) + transform.pos;
        }

        pub fn rotate(transform: Transform, vec: @Vector(n, Element)) @Vector(n, Element) {
            return transform.rot.apply(vec);
        }

        ///```
        ///  a   b
        ///*-->*-->*
        ///```
        pub fn add(a: Transform, b: Transform) Transform {
            return .{
                .rot = b.rot.mul(a.rot),
                .pos = b.rot.apply(a.pos) + b.pos,
            };
        }
    };
}
