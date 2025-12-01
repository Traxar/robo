const c = @import("../c.zig").c;

const Program = @This();

id: c_uint,

pub fn initRender(vert_glsl: [*c]const u8, frag_glsl: [*c]const u8) Program {
    return .{
        .id = c.LoadShaderFromMemory(vert_glsl, frag_glsl).id,
    };
}

pub fn initCompute(comp_glsl: [*c]const u8) Program {
    return .{
        .id = c.rlLoadComputeShaderProgram(comp_glsl),
    };
}

pub fn deinit(program: Program) void {
    c.rlUnloadShaderProgram(program.id);
}

pub fn locationUniform(program: Program, name: [*c]const u8) ?c_int {
    const id = c.rlGetLocationUniform(program.id, name);
    return if (id != -1) id else null;
}

pub fn locationInput(program: Program, name: [*c]const u8) ?c_int {
    const id = c.rlGetLocationAttrib(program.id, name);
    return if (id != -1) id else null;
}
