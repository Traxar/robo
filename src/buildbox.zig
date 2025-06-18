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
    pub const scale = 3;

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
            assert(@reduce(.And, placement.position > @as(Position, @splat(std.math.minInt(i8)))));
            assert(@reduce(.And, placement.position < @as(Position, @splat(std.math.maxInt(i8)))));
            box.bounds.add(placement.position);
        }
        const size: Index = @intCast(box.bounds.max + @as(Position, @splat(1)) - box.bounds.min);
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

    pub fn at(a: BuildBox, b: Position) bool {
        return a.values[a.index(b)];
    }

    /// a   p   b
    /// *------>*
    pub fn collides(a: BuildBox, p: Placement, b: BuildBox) bool {
        const p_ = Placement{ .position = p.position };
        const b_ = _: {
            var b_ = b.bounds.placeSat(p);
            inline for (1..scale) |_| {
                b_ = b_.placeSat(p_);
            }
            break :_ b_;
        };
        if (a.bounds.intersect(b_)) |itersection| {
            //no unnecessary overlaps will be detected
            //since: MIN < a.min and a.max < MAX
            const q = p.inv();
            const q_ = p_.inv();
            var iter = itersection.min;
            while (true) : (if (!itersection.next(&iter)) break) {
                if (!a.at(iter)) continue;
                const iter_ = _: {
                    var iter_ = Placement{ .position = iter };
                    inline for (1..scale) |_| {
                        iter_ = q_.place(iter_) catch unreachable;
                    }
                    break :_ (q.place(iter_) catch unreachable).position;
                };
                if (b.at(iter_)) return true;
            }
        }
        return false;
    }
};
