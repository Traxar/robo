const std = @import("std");
const assert = std.debug.assert;
const o = @import("o.zig");
const c = o.c;

const buffer_size = 1 << 11;
var buffer: [buffer_size]RenderInfo = undefined;
var length: usize = 0;
var model: o.Model = undefined;

var vertexBuffer: o.gpu.VertexBuffer(RenderInfo, .{ .write = .{ .by = .cpu, .n = .many } }) = undefined;

pub var shader: o.gpu.Program = undefined;

const RenderColor = [4]f32;
const RenderTransform = [12]f32;

const RenderInfo = struct {
    transform: RenderTransform,
    color: RenderColor,
};

pub fn init() !void {
    if (@sizeOf(RenderInfo) != 16 * @sizeOf(f32)) @compileError("nope");
    shader = .initRender(
        @embedFile("shaders/instanced.vert.glsl"),
        @embedFile("shaders/instanced.frag.glsl"),
    );
    c.rlDisableBackfaceCulling(); //?workaround as shader does not (yet) support flipped placements

    vertexBuffer = try .init(&buffer);
    errdefer vertexBuffer.deinit();
}

pub fn deinit() void {
    vertexBuffer.deinit();

    shader.deinit();
}

pub fn drawBuffer() void {
    if (length == 0) return;
    //? instancing shader needed
    for (0..@intCast(model.internal.meshCount)) |i| {
        drawMeshInstanced(
            .{ .internal = model.internal.meshes[i] },
            model.internal.materials[@intCast(model.internal.meshMaterial[i])],
            buffer[0..length],
        );
    }
    length = 0;
}

pub fn addToBuffer(model_: o.Model, color: o.Color, transform: o.Transform) void {
    if (!std.meta.eql(model_, model)) drawBuffer();
    if (length == 0) {
        model = model_;
    }
    buffer[length].transform = .{
        transform.rot.col[0][0],
        transform.rot.col[0][1],
        transform.rot.col[0][2],
        transform.rot.col[1][0],
        transform.rot.col[1][1],
        transform.rot.col[1][2],
        transform.rot.col[2][0],
        transform.rot.col[2][1],
        transform.rot.col[2][2],
        transform.pos[0],
        transform.pos[1],
        transform.pos[2],
    };
    buffer[length].color = .{
        @as(f32, @floatFromInt(color.rgba[0])) / 255.0,
        @as(f32, @floatFromInt(color.rgba[1])) / 255.0,
        @as(f32, @floatFromInt(color.rgba[2])) / 255.0,
        @as(f32, @floatFromInt(color.rgba[3])) / 255.0,
    };
    length += 1;
    if (length == buffer_size) drawBuffer();
}

fn drawMeshInstanced(mesh: o.Mesh, material: c.Material, renderInfos: []RenderInfo) void {
    // Bind shader program
    c.rlEnableShader(shader.id);

    // Send required data to shader (matrices, values)
    //-----------------------------------------------------
    // Upload to shader material.colDiffuse
    if (shader.locationUniform("colDiffuse")) |loc| {
        const values: @Vector(4, f32) = .{ 1.0, 1.0, 1.0, 1.0 };
        c.rlSetUniform(loc, &values, c.SHADER_UNIFORM_VEC4, 1);
    }

    if (shader.locationUniform("texture0")) |loc| {
        const i: c_int = 0;
        c.rlActiveTextureSlot(i);
        c.rlEnableTexture(material.maps[i].texture.id);
        c.rlSetUniform(loc, &i, c.SHADER_UNIFORM_INT, 1);
    }

    const matView = c.rlGetMatrixModelview();
    const matProjection = c.rlGetMatrixProjection();
    const matModelView = c.MatrixMultiply(c.rlGetMatrixTransform(), matView);
    const matModelViewProjection = c.MatrixMultiply(matModelView, matProjection);

    // Send combined model-view-projection matrix to shader
    if (shader.locationUniform("mvp")) |loc|
        c.rlSetUniformMatrix(loc, matModelViewProjection);

    // Get a copy of current matrices to work with,
    // just in case stereo render is required, and we need to modify them
    // NOTE: At this point the modelview matrix just contains the view matrix (camera)
    // That's because BeginMode3D() sets it and there is no model-drawing function
    // that modifies it, all use rlPushMatrix() and rlPopMatrix()

    // Upload view and projection matrices (if locations available)

    // Enable mesh VAO to attach new buffer
    _ = c.rlEnableVertexArray(mesh.internal.vaoId);

    vertexBuffer.update(0, renderInfos);

    // Instances transformation matrices are sent to shader attribute location: SHADER_LOC_VERTEX_INSTANCE_TX
    if (shader.locationInput("instanceTransform")) |loc| {
        for (0..4) |i_| {
            const i: c_int = @intCast(i_);
            c.rlEnableVertexAttribute(@intCast(loc + i));
            o.setVertexAttribute(loc + i, @Vector(3, f32), 16, 3 * i_);
            c.rlSetVertexAttributeDivisor(@intCast(loc + i), 1);
        }
    }

    if (shader.locationInput("instanceColor")) |loc| {
        c.rlEnableVertexAttribute(@intCast(loc));
        o.setVertexAttribute(loc, @Vector(4, f32), 16, 12);
        c.rlSetVertexAttributeDivisor(@intCast(loc), 1);
    }

    if (shader.locationInput("vertexPosition")) |loc| {
        c.rlEnableVertexBuffer(mesh.internal.vboId[c.RL_DEFAULT_SHADER_ATTRIB_LOCATION_POSITION]);
        c.rlSetVertexAttribute(@intCast(loc), 3, c.RL_FLOAT, false, 0, 0);
        c.rlEnableVertexAttribute(@intCast(loc));
    }

    if (shader.locationInput("vertexTexCoord")) |loc| {
        c.rlEnableVertexBuffer(mesh.internal.vboId[c.RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD]);
        c.rlSetVertexAttribute(@intCast(loc), 2, c.RL_FLOAT, false, 0, 0);
        c.rlEnableVertexAttribute(@intCast(loc));
    }

    if (shader.locationInput("vertexNormal")) |loc| {
        c.rlEnableVertexBuffer(mesh.internal.vboId[c.RL_DEFAULT_SHADER_ATTRIB_LOCATION_NORMAL]);
        c.rlSetVertexAttribute(@intCast(loc), 3, c.RL_FLOAT, false, 0, 0);
        c.rlEnableVertexAttribute(@intCast(loc));
    }

    c.rlEnableVertexBufferElement(mesh.internal.vboId[c.RL_DEFAULT_SHADER_ATTRIB_LOCATION_INDICES]);

    //draw
    c.rlDrawVertexArrayInstanced(0, mesh.internal.vertexCount, @intCast(renderInfos.len));

    c.rlActiveTextureSlot(0);
    c.rlDisableTexture();
    c.rlDisableVertexArray();
    c.rlDisableVertexBuffer();
    c.rlDisableVertexBufferElement();
    c.rlDisableShader();
}
