const std = @import("std");
const assert = std.debug.assert;
const c = @import("c.zig");

const buffer_size = 20000;
var buffer: [buffer_size]c.Matrix = undefined;
var length: usize = 0;
var model: c.Model = undefined;
var color: c.Color = undefined;

pub fn drawBuffer() void {
    if (length == 0) return;
    model
        .materials[@intCast(model.meshMaterial[0])]
        .maps[c.MATERIAL_MAP_DIFFUSE]
        .color = color;
    //? instancing shader needed
    for (0..@intCast(model.meshCount)) |i| {
        c.DrawMeshInstanced(
            model.meshes[i],
            model.materials[@intCast(model.meshMaterial[i])],
            &buffer,
            @intCast(length),
        );
    }
    length = 0;
}

pub fn addToBuffer(model_: c.Model, color_: c.Color, transform: c.Matrix) void {
    if (length == buffer_size or (length > 0 and (!std.meta.eql(model_, model) or !std.meta.eql(color_, color)))) {
        drawBuffer();
    }
    if (length == 0) {
        model = model_;
        color = color_;
    }
    buffer[length] = transform;
    length += 1;
}
