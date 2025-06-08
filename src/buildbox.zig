const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const Placement = @import("placement.zig").Placement;
const Position = Placement.Position;
const BoundingBox = Placement.BoundingBox;
const Robot = @import("robot.zig").Type(.{
    .mark_collisions = false,
});

pub const BuildBox = struct {
    const I = u32;
    const Index = @Vector(3, I);

    bounds: BoundingBox,
    increment: Index,
    values: []bool,

    pub fn init(robot: Robot, gpa: Allocator) !BuildBox {
        var box = BuildBox{
            .bounds = BoundingBox.none,
            .increment = @splat(1),
            .values = undefined,
        };
        for (
            robot.parts.items(.part),
            robot.parts.items(.placement),
        ) |part, placement| {
            assert(part == .cube); //only cubes allowed
            box.bounds.add(placement.position);
        }
        const size = @max(0, box.bounds.max + @as(Position, @splat(1)) - box.bounds.min);
        for (1..3) |i| {
            box.increment[i] = box.increment[i - 1] * size[i - 1];
        }
        const len = box.increment[2] * size[2];
        if (len > 0) {
            box.values = try gpa.alloc(bool, len);
            @memset(box.values, false);
            for (robot.parts.items(.placement)) |placement| {
                box.values[box.index(placement.position)] = true;
            }
        }
        return box;
    }

    pub fn deinit(a: BuildBox, gpa: Allocator) void {
        gpa.free(a.values);
    }

    fn index(a: BuildBox, b: Position) I {
        return @reduce(.Add, a.increment * @as(Index, @intCast(b - a.bounds.min)));
    }

    fn at(a: BuildBox, b: Position) bool {
        return a.values[a.index(b)];
    }

    /// a   p   b
    /// *------>*
    pub fn collide(a: BuildBox, p: Placement, b: BuildBox) bool {
        const q = p.inv();
        if (a.bounds.intersect(b.bounds.place(p))) |itersection| {
            var iter = itersection.min;
            while (true) {
                if (a.at(iter) and b.at(q.move(iter).position)) return true;
                if (!itersection.next(&iter)) break;
            }
        }
        return false;
    }
};
