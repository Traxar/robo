const std = @import("std");
const builtin = @import("builtin");
const panic = @import("util.zig").panic;

var current: State = .none;

const State = enum {
    none, //root
    window,
    draw,
    render,

    fn parent(from: State) State {
        return switch (from) {
            .none => unreachable,
            .window => .none,
            .draw => .window,
            .render => .draw,
        };
    }
};

pub fn is(expect: State) void {
    if (current != expect) std.debug.panic(
        "expected state.{s} found state.{s}",
        .{ @tagName(expect), @tagName(current) },
    );
}

pub fn has(expect: State) void {
    if (expect == .none) return;
    var runner = current;
    while (runner != .none) {
        if (runner == expect) return;
        runner = runner.parent();
    }
    std.debug.panic(
        "expected a decendent of state.{s} found state.{s}",
        .{ @tagName(expect), @tagName(current) },
    );
}

pub fn begin(new: State) void {
    if (new.parent() != current) std.debug.panic(
        "state.{s} cannot be started from state.{s}",
        .{ @tagName(new), @tagName(current) },
    );
    current = new;
}

pub fn end(current_: State) void {
    is(current_);
    current = current.parent();
}
