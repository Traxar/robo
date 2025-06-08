const PlacementType = @import("placement.zig").PlacementType;

pub fn Type(T: type) type {
    return struct {
        const BoundingBox = @This();
        const Placement = PlacementType(T);
        const Position = Placement.Position;
        min: Position,
        max: Position, //inclusive

        pub const none = BoundingBox{ .min = @splat(1), .max = @splat(0) };

        fn empty(a: BoundingBox) bool {
            return @reduce(.Or, a.min > a.max);
        }

        pub fn add(a: *BoundingBox, b: Position) void {
            if (a.empty()) {
                a.min = b;
                a.max = b;
            } else {
                a.min = @min(a.min, b);
                a.max = @max(a.max, b);
            }
        }

        pub fn intersect(a: BoundingBox, b: BoundingBox) ?BoundingBox {
            const c = .{
                .min = @max(a.min, b.min),
                .max = @min(a.max, b.max),
            };
            return if (c.empty()) null else c;
        }

        pub fn place(a: BoundingBox, b: Placement) BoundingBox {
            var c = BoundingBox.none;
            c.add(b.move(a.min).position);
            c.add(b.move(a.max).position);
            return c;
        }

        pub fn next(a: BoundingBox, b: *Position) bool {
            inline for (0..3) |i| {
                if (b[i] < a.max[i]) {
                    b[i] += 1;
                    return true;
                } else {
                    b[i] = a.min[i];
                }
            }
            return false;
        }
    };
}
