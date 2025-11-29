///column major
pub fn Type(n: usize, Element: type) type {
    return struct {
        const Matrix = @This();

        col: [n]@Vector(n, Element),

        pub const zero: Matrix = .{ .col = @splat(@splat(0)) };

        pub fn diag(vec: @Vector(n, Element)) Matrix {
            var result = zero;
            for (0..3) |i| {
                result.col[i][i] = vec[i];
            }
            return result;
        }

        pub fn apply(mat: Matrix, vec: @Vector(n, Element)) @Vector(n, Element) {
            var result: @Vector(n, Element) = @splat(0);
            for (0..n) |i| {
                result += mat.col[i] * @as(@Vector(n, Element), @splat(vec[i]));
            }
            return result;
        }

        pub fn mul(mat: Matrix, other: Matrix) Matrix {
            var result: Matrix = undefined;
            for (0..n) |i| {
                result.col[i] = mat.apply(other.col[i]);
            }
            return result;
        }
    };
}
