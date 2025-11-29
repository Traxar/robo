const std = @import("std");
const Allocator = std.mem.Allocator;
const o = @import("o.zig");
const renderer = @import("renderer.zig");
const parts = @import("parts.zig");
const State = @import("state.zig").State;
const misc = @import("misc.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
var state: State = undefined;

pub fn main() !void {
    try init();
    defer deinit();
    while (!o.window.shouldClose() and try state.run()) {}
}

fn init() !void {
    o.window.begin(1280, 720, "robo");
    errdefer o.window.end();

    // working directory
    const dir_path = try std.fs.selfExeDirPathAlloc(allocator);
    defer allocator.free(dir_path);
    try misc.set_cwd(dir_path);
    try misc.cwd("..");
    try misc.cwd("..");
    renderer.init();
    try parts.loadData(allocator);

    state = try State.init(allocator);
}

fn deinit() void {
    state.deinit();
    parts.unloadData(allocator);
    renderer.deinit();
    o.window.end();
    if (gpa.deinit() == .leak) @panic("MEMORY LEAKED");
}
