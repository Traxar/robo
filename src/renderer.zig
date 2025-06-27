const std = @import("std");
const assert = std.debug.assert;
const c = @import("c.zig");

const buffer_size = 20000;
var transform_buffer: [buffer_size][16]f32 = undefined;
var color_buffer: [buffer_size][4]f32 = undefined;
var length: usize = 0;
var model: c.Model = undefined;

pub fn drawBuffer() void {
    if (length == 0) return;
    //? instancing shader needed
    for (0..@intCast(model.meshCount)) |i| {
        drawMeshInstanced(
            model.meshes[i],
            model.materials[@intCast(model.meshMaterial[i])],
            transform_buffer[0..length],
            color_buffer[0..length],
        );
    }
    length = 0;
}

pub fn addToBuffer(model_: c.Model, color: c.Color, transform: c.Matrix) void {
    if (!std.meta.eql(model_, model)) drawBuffer();
    if (length == 0) {
        model = model_;
    }
    transform_buffer[length] = .{
        transform.m0,
        transform.m1,
        transform.m2,
        transform.m3,
        transform.m4,
        transform.m5,
        transform.m6,
        transform.m7,
        transform.m8,
        transform.m9,
        transform.m10,
        transform.m11,
        transform.m12,
        transform.m13,
        transform.m14,
        transform.m15,
    };
    color_buffer[length] = .{
        @as(f32, @floatFromInt(color.r)) / 255.0,
        @as(f32, @floatFromInt(color.g)) / 255.0,
        @as(f32, @floatFromInt(color.b)) / 255.0,
        @as(f32, @floatFromInt(color.a)) / 255.0,
    };
    length += 1;
    if (length == buffer_size) drawBuffer();
}

fn drawMeshInstanced(mesh: c.Mesh, material: c.Material, transforms: [][16]f32, colors: [][4]f32) void {
    // Bind shader program
    c.rlEnableShader(material.shader.id);

    // Send required data to shader (matrices, values)
    //-----------------------------------------------------
    // Upload to shader material.colDiffuse
    if (material.shader.locs[c.SHADER_LOC_COLOR_DIFFUSE] != -1) {
        const values = [_]f32{
            @as(f32, @floatFromInt(material.maps[c.MATERIAL_MAP_DIFFUSE].color.r)) / 255.0,
            @as(f32, @floatFromInt(material.maps[c.MATERIAL_MAP_DIFFUSE].color.g)) / 255.0,
            @as(f32, @floatFromInt(material.maps[c.MATERIAL_MAP_DIFFUSE].color.b)) / 255.0,
            @as(f32, @floatFromInt(material.maps[c.MATERIAL_MAP_DIFFUSE].color.a)) / 255.0,
        };

        c.rlSetUniform(material.shader.locs[c.SHADER_LOC_COLOR_DIFFUSE], &values, c.SHADER_UNIFORM_VEC4, 1);
    }

    // Get a copy of current matrices to work with,
    // just in case stereo render is required, and we need to modify them
    // NOTE: At this point the modelview matrix just contains the view matrix (camera)
    // That's because BeginMode3D() sets it and there is no model-drawing function
    // that modifies it, all use rlPushMatrix() and rlPopMatrix()
    const matModel = c.MatrixIdentity();
    const matView = c.rlGetMatrixModelview();
    const matProjection = c.rlGetMatrixProjection();

    // Upload view and projection matrices (if locations available)
    if (material.shader.locs[c.SHADER_LOC_MATRIX_VIEW] != -1)
        c.rlSetUniformMatrix(material.shader.locs[c.SHADER_LOC_MATRIX_VIEW], matView);
    if (material.shader.locs[c.SHADER_LOC_MATRIX_PROJECTION] != -1)
        c.rlSetUniformMatrix(material.shader.locs[c.SHADER_LOC_MATRIX_PROJECTION], matProjection);

    // Enable mesh VAO to attach new buffer
    _ = c.rlEnableVertexArray(mesh.vaoId);

    const transformsVboId = c.rlLoadVertexBuffer(transforms.ptr, @intCast(transforms.len * @sizeOf([16]f32)), false);

    // Instances transformation matrices are sent to shader attribute location: SHADER_LOC_VERTEX_INSTANCE_TX
    for (0..4) |i_| {
        const i: c_int = @intCast(i_);
        c.rlEnableVertexAttribute(@intCast(material.shader.locs[c.SHADER_LOC_VERTEX_INSTANCE_TX] + i));
        c.rlSetVertexAttribute(@intCast(material.shader.locs[c.SHADER_LOC_VERTEX_INSTANCE_TX] + i), 4, c.RL_FLOAT, false, @intCast(@sizeOf([16]f32)), @intCast(i * @sizeOf([4]f32)));
        c.rlSetVertexAttributeDivisor(@intCast(material.shader.locs[c.SHADER_LOC_VERTEX_INSTANCE_TX] + i), 1);
    }
    c.rlDisableVertexBuffer();

    const colorsVboId = c.rlLoadVertexBuffer(colors.ptr, @intCast(colors.len * @sizeOf([4]f32)), false);

    // Instances transformation matrices are sent to shader attribute location: SHADER_LOC_VERTEX_INSTANCE_CX
    c.rlEnableVertexAttribute(@intCast(material.shader.locs[c.SHADER_LOC_VERTEX_INSTANCE_TX + 1]));
    c.rlSetVertexAttribute(@intCast(material.shader.locs[c.SHADER_LOC_VERTEX_INSTANCE_TX + 1]), 4, c.RL_FLOAT, false, @intCast(@sizeOf([4]f32)), 0);
    c.rlSetVertexAttributeDivisor(@intCast(material.shader.locs[c.SHADER_LOC_VERTEX_INSTANCE_TX + 1]), 1);

    c.rlDisableVertexBuffer();

    c.rlDisableVertexArray();

    // Accumulate internal matrix transform (push/pop) and view matrix
    // NOTE: In this case, model instance transformation must be computed in the shader
    const matModelView = c.MatrixMultiply(c.rlGetMatrixTransform(), matView);

    // Upload model normal matrix (if locations available)
    if (material.shader.locs[c.SHADER_LOC_MATRIX_NORMAL] != -1)
        c.rlSetUniformMatrix(material.shader.locs[c.SHADER_LOC_MATRIX_NORMAL], c.MatrixTranspose(c.MatrixInvert(matModel)));

    //-----------------------------------------------------

    // Bind active texture maps (if available)
    for (0..12) |i_| {
        const i: c_int = @intCast(i_);
        if (material.maps[i_].texture.id > 0) {
            // Select current shader texture slot
            c.rlActiveTextureSlot(i);

            // Enable texture for active slot
            if ((i == c.MATERIAL_MAP_IRRADIANCE) or
                (i == c.MATERIAL_MAP_PREFILTER) or
                (i == c.MATERIAL_MAP_CUBEMAP))
            {
                c.rlEnableTextureCubemap(material.maps[i_].texture.id);
            } else {
                c.rlEnableTexture(material.maps[i_].texture.id);
            }

            c.rlSetUniform(material.shader.locs[@intCast(c.SHADER_LOC_MAP_DIFFUSE + i)], &i, c.SHADER_UNIFORM_INT, 1);
        }
    }

    // Try binding vertex array objects (VAO)
    // or use VBOs if not possible
    if (!c.rlEnableVertexArray(mesh.vaoId)) {
        // Bind mesh VBO data: vertex position (shader-location = 0)
        c.rlEnableVertexBuffer(mesh.vboId[c.RL_DEFAULT_SHADER_ATTRIB_LOCATION_POSITION]);
        c.rlSetVertexAttribute(@intCast(material.shader.locs[c.SHADER_LOC_VERTEX_POSITION]), 3, c.RL_FLOAT, false, 0, 0);
        c.rlEnableVertexAttribute(@intCast(material.shader.locs[c.SHADER_LOC_VERTEX_POSITION]));

        // Bind mesh VBO data: vertex texcoords (shader-location = 1)
        c.rlEnableVertexBuffer(mesh.vboId[c.RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD]);
        c.rlSetVertexAttribute(@intCast(material.shader.locs[c.SHADER_LOC_VERTEX_TEXCOORD01]), 2, c.RL_FLOAT, false, 0, 0);
        c.rlEnableVertexAttribute(@intCast(material.shader.locs[c.SHADER_LOC_VERTEX_TEXCOORD01]));

        if (material.shader.locs[c.SHADER_LOC_VERTEX_NORMAL] != -1) {
            // Bind mesh VBO data: vertex normals (shader-location = 2)
            c.rlEnableVertexBuffer(mesh.vboId[c.RL_DEFAULT_SHADER_ATTRIB_LOCATION_NORMAL]);
            c.rlSetVertexAttribute(@intCast(material.shader.locs[c.SHADER_LOC_VERTEX_NORMAL]), 3, c.RL_FLOAT, false, 0, 0);
            c.rlEnableVertexAttribute(@intCast(material.shader.locs[c.SHADER_LOC_VERTEX_NORMAL]));
        }

        // Bind mesh VBO data: vertex colors (shader-location = 3, if available)
        if (material.shader.locs[c.SHADER_LOC_VERTEX_COLOR] != -1) {
            if (mesh.vboId[c.RL_DEFAULT_SHADER_ATTRIB_LOCATION_COLOR] != 0) {
                c.rlEnableVertexBuffer(mesh.vboId[c.RL_DEFAULT_SHADER_ATTRIB_LOCATION_COLOR]);
                c.rlSetVertexAttribute(@intCast(material.shader.locs[c.SHADER_LOC_VERTEX_COLOR]), 4, c.RL_UNSIGNED_BYTE, true, 0, 0);
                c.rlEnableVertexAttribute(@intCast(material.shader.locs[c.SHADER_LOC_VERTEX_COLOR]));
            } else {
                // Set default value for unused attribute
                // NOTE: Required when using default shader and no VAO support
                const value = [_]f32{ 1.0, 1.0, 1.0, 1.0 };
                c.rlSetVertexAttributeDefault(material.shader.locs[c.SHADER_LOC_VERTEX_COLOR], &value, c.SHADER_ATTRIB_VEC4, 4);
                c.rlDisableVertexAttribute(@intCast(material.shader.locs[c.SHADER_LOC_VERTEX_COLOR]));
            }
        }

        // Bind mesh VBO data: vertex tangents (shader-location = 4, if available)
        if (material.shader.locs[c.SHADER_LOC_VERTEX_TANGENT] != -1) {
            c.rlEnableVertexBuffer(mesh.vboId[c.RL_DEFAULT_SHADER_ATTRIB_LOCATION_TANGENT]);
            c.rlSetVertexAttribute(@intCast(material.shader.locs[c.SHADER_LOC_VERTEX_TANGENT]), 4, c.RL_FLOAT, false, 0, 0);
            c.rlEnableVertexAttribute(@intCast(material.shader.locs[c.SHADER_LOC_VERTEX_TANGENT]));
        }

        // Bind mesh VBO data: vertex texcoords2 (shader-location = 5, if available)
        if (material.shader.locs[c.SHADER_LOC_VERTEX_TEXCOORD02] != -1) {
            c.rlEnableVertexBuffer(mesh.vboId[c.RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD2]);
            c.rlSetVertexAttribute(@intCast(material.shader.locs[c.SHADER_LOC_VERTEX_TEXCOORD02]), 2, c.RL_FLOAT, false, 0, 0);
            c.rlEnableVertexAttribute(@intCast(material.shader.locs[c.SHADER_LOC_VERTEX_TEXCOORD02]));
        }

        if (mesh.indices != null) c.rlEnableVertexBufferElement(mesh.vboId[c.RL_DEFAULT_SHADER_ATTRIB_LOCATION_INDICES]);
    }

    const eyeCount: usize = if (c.rlIsStereoRenderEnabled()) 2 else 1;

    for (0..eyeCount) |eye_| {
        const eye: c_int = @intCast(eye_);
        // Calculate model-view-projection matrix (MVP)
        var matModelViewProjection = c.MatrixIdentity();
        if (eyeCount == 1) {
            matModelViewProjection = c.MatrixMultiply(matModelView, matProjection);
        } else {
            // Setup current eye viewport (half screen width)
            c.rlViewport(@divFloor(eye * c.rlGetFramebufferWidth(), 2), 0, @divFloor(c.rlGetFramebufferWidth(), 2), c.rlGetFramebufferHeight());
            matModelViewProjection = c.MatrixMultiply(c.MatrixMultiply(matModelView, c.rlGetMatrixViewOffsetStereo(eye)), c.rlGetMatrixProjectionStereo(eye));
        }

        // Send combined model-view-projection matrix to shader
        c.rlSetUniformMatrix(material.shader.locs[c.SHADER_LOC_MATRIX_MVP], matModelViewProjection);

        // Draw mesh instanced
        if (mesh.indices != null) {
            c.rlDrawVertexArrayElementsInstanced(0, mesh.triangleCount * 3, null, @intCast(transforms.len));
        } else {
            c.rlDrawVertexArrayInstanced(0, mesh.vertexCount, @intCast(transforms.len));
        }
    }

    // Unbind all bound texture maps
    for (0..12) |i_| {
        const i: c_int = @intCast(i_);
        if (material.maps[i_].texture.id > 0) {
            // Select current shader texture slot
            c.rlActiveTextureSlot(i);

            // Disable texture for active slot
            if ((i == c.MATERIAL_MAP_IRRADIANCE) or
                (i == c.MATERIAL_MAP_PREFILTER) or
                (i == c.MATERIAL_MAP_CUBEMAP))
            {
                c.rlDisableTextureCubemap();
            } else {
                c.rlDisableTexture();
            }
        }
    }

    // Disable all possible vertex array objects (or VBOs)
    c.rlDisableVertexArray();
    c.rlDisableVertexBuffer();
    c.rlDisableVertexBufferElement();

    // Disable shader program
    c.rlDisableShader();

    // Remove instance transforms buffer
    c.rlUnloadVertexBuffer(transformsVboId);
    c.rlUnloadVertexBuffer(colorsVboId);
}
