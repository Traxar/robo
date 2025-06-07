const PlacementType = @import("placement.zig").PlacementType;

pub fn Type(T: type) type {
    return struct {
        const BoundingBox = @This();
        const Placement = PlacementType(T);
        const Position = Placement.Position;
        min: Position,
        max: Position,

        const ones: Position = @splat(1);
        pub const none = BoundingBox{ .min = @splat(0), .max = @splat(0) };

        pub fn add(a: *BoundingBox, b: Position) void {
            if (@reduce(.Or, a.min >= b)) {
                a.min = b;
                a.max = b + ones;
            } else {
                a.min = @min(a.min, b);
                a.max = @max(a.max, b + ones);
            }
        }

        pub fn intersect(a: BoundingBox, b: BoundingBox) ?BoundingBox {
            const c = .{
                .min = @max(a.min, b.min),
                .max = @min(a.max, b.max),
            };
            if (@reduce(.Or, c.min >= c.max)) return null;
            return c;
        }

        pub fn place(a: BoundingBox, b: Placement) BoundingBox {
            var c = BoundingBox.none;
            c.add(b.move(a.min).position);
            c.add(b.move(a.max - ones).position);
            return c;
        }
    };
}
