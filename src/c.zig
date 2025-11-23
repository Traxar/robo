const math = @import("std").math;

pub const c = @cImport({
    @cInclude("raylib.h");
    @cInclude("rlgl.h");
    @cInclude("raymath.h");
    @cDefine("RAYGUI_IMPLEMENTATION", {});
    @cInclude("raygui.h");
});

pub const Vec2 = @Vector(2, f32);
pub const Vec3 = @Vector(3, f32);
pub const Mat3 = struct {
    col: [3]Vec3,

    pub const zero: Mat3 = .{ .col = @splat(@splat(0)) };

    pub fn diag(vec: Vec3) Mat3 {
        var result = zero;
        for (0..3) |i| {
            result.col[i][i] = vec[i];
        }
        return result;
    }

    pub fn apply(mat: Mat3, vec: Vec3) Vec3 {
        var result: Vec3 = @splat(0);
        for (0..3) |i| {
            result += mat.col[i] * @as(Vec3, @splat(vec[i]));
        }
        return result;
    }

    pub fn mul(mat: Mat3, other: Mat3) Mat3 {
        var result: Mat3 = undefined;
        for (0..3) |i| {
            result.col[i] = mat.apply(other.col[i]);
        }
        return result;
    }
}; //column major
pub const Transform = struct {
    rot: Mat3,
    pos: Vec3,

    pub const none: Transform = .{
        .rot = .{
            .{ 1, 0, 0 },
            .{ 0, 1, 0 },
            .{ 0, 0, 1 },
        },
        .pos = .{ 0, 0, 0 },
    };

    pub fn apply(transform: Transform, vec: Vec3) Vec3 {
        return transform.rotate(vec) + transform.pos;
    }

    pub fn rotate(transform: Transform, vec: Vec3) Vec3 {
        return transform.rot.apply(vec);
    }

    ///```
    ///  a   b
    ///*-->*-->*
    ///```
    pub fn add(a: Transform, b: Transform) Transform {
        return .{
            .rot = b.rot.mul(a.rot),
            .pos = b.rot.apply(a.pos) + b.pos,
        };
    }
};

pub const Window = struct {
    pub fn init(width: usize, height: usize, title: [*c]const u8) !void {
        c.InitWindow(@intCast(width), @intCast(height), title);
        c.SetExitKey(c.KEY_NULL);
    }

    pub fn deinit() void {
        c.CloseWindow();
    }

    pub fn shouldClose() bool {
        return c.WindowShouldClose();
    }

    pub fn mousePosition() Vec2 {
        const a = c.GetMousePosition();
        return .{ a.x, a.y };
    }

    pub fn monitor() Monitor {
        return Monitor{ .id = c.GetCurrentMonitor() };
    }
};

pub const Fps = struct {
    pub fn set(fps: usize) void {
        c.SetTargetFPS(@intCast(fps));
    }
};

pub const Monitor = struct {
    id: c_int,

    pub fn rate(monitor: Monitor) usize {
        return @intCast(c.GetMonitorRefreshRate(monitor.id));
    }
};

pub const Ray = struct {
    pos: Vec3,
    dir: Vec3,

    /// point = ray.pos + ray.dir * hit.dist
    pub const Hit = struct {
        dist: f32,
        normal: Vec3,
    };

    /// returns a hit if and only if ray hits box from outside
    pub fn boundingBox(ray: Ray, boundingBox_: BoundingBox) ?Hit {
        // pos + t_0 * dir = min
        // pos + t_1 * dir = max
        const t_0 = (boundingBox_.min - ray.pos) / ray.dir;
        const t_1 = (boundingBox_.max - ray.pos) / ray.dir;

        const t_min = @min(t_0, t_1);
        const t_max = @max(t_0, t_1);

        const t = @reduce(.Max, t_min);
        if (t < 0) return null;
        if (@reduce(.Min, t_max) < t) return null;
        const t_: Vec3 = @splat(t);
        const one: Vec3 = @splat(1);
        const zero: Vec3 = @splat(0);
        return .{
            .dist = t,
            .normal = @select(f32, t_1 == t_, one, zero) - @select(f32, t_0 == t_, one, zero),
        };
    }

    pub fn mesh(ray: Ray, mesh_: Mesh) ?Hit {
        const r = c.GetRayCollisionMesh(ray.raylib(), mesh_.internal, comptime c.MatrixIdentity());
        if (!r.hit) return null;
        return .{
            .dist = r.distance,
            .normal = fromVector3(r.normal),
        };
    }

    fn raylib(ray: Ray) c.Ray {
        return .{
            .direction = .{
                .x = ray.dir[0],
                .y = ray.dir[1],
                .z = ray.dir[2],
            },
            .position = .{
                .x = ray.pos[0],
                .y = ray.pos[1],
                .z = ray.pos[2],
            },
        };
    }
};

pub const BoundingBox = struct {
    min: Vec3,
    max: Vec3,
};

pub const Model = struct {
    internal: c.Model,

    pub fn load(fileName: [*c]const u8) Model {
        return .{
            .internal = c.LoadModel(fileName),
        };
    }

    pub fn unload(model: Model) void {
        c.UnloadModel(model.internal);
    }

    pub fn bounds(model: Model) BoundingBox {
        const b = c.GetModelBoundingBox(model.internal);
        return .{
            .min = .{ b.min.x, b.min.y, b.min.z },
            .max = .{ b.max.x, b.max.y, b.max.z },
        };
    }
};

pub const Shader = struct {
    internal: c.Shader,

    pub fn load(vert_glsl: [*c]const u8, frag_glsl: [*c]const u8) Shader {
        return .{
            .internal = c.LoadShaderFromMemory(vert_glsl, frag_glsl),
        };
    }

    pub fn unload(shader: Shader) void {
        c.UnloadShader(shader.internal);
    }

    pub fn locationUniform(shader: Shader, name: [*c]const u8) c_int {
        return c.GetShaderLocation(shader.internal, name);
    }

    pub fn locationInput(shader: Shader, name: [*c]const u8) c_int {
        return c.GetShaderLocationAttrib(shader.internal, name);
    }
};

pub const Mesh = struct {
    internal: c.Mesh,
};

pub const Camera = struct {
    position: Vec3,
    rotation: Vec2 = undefined, // yaw, pitch
    options: Options = .{},

    pub const Options = struct {
        fovy: f32 = 45,
        forward_relative_to_camera: bool = true,
        up_relative_to_camera: bool = true,
    };

    pub fn update(camera: *Camera, movement: Vec3, rotation: Vec2, options: Options) void {
        camera.rotation += rotation;
        camera.fixRotation();
        const sin = @sin(camera.rotation);
        const cos = @cos(camera.rotation);
        camera.position += @as(Vec3, @splat(movement[0])) * right(sin, cos);
        camera.position += @as(Vec3, @splat(movement[1])) * forward(sin, cos, options.forward_relative_to_camera);
        camera.position += @as(Vec3, @splat(movement[2])) * up(sin, cos, options.up_relative_to_camera);
    }

    pub fn target(camera: *Camera, position: Vec3) void {
        const diff = position - camera.position;
        const norm = @reduce(.Add, diff * diff);
        if (norm <= 0) return;
        const dir = diff / @as(Vec3, @splat(@sqrt(norm)));
        camera.rotation[1] = math.asin(dir[2]);
        camera.rotation[0] = math.atan2(-dir[0], dir[1]);
    }

    fn fixRotation(camera: *Camera) void {
        camera.rotation[0] = @mod(camera.rotation[0], 2 * math.pi);
        camera.rotation[1] = @max(-math.pi / 2.0, @min(math.pi / 2.0, camera.rotation[1]));
    }

    fn forward(sin: Vec2, cos: Vec2, relative_to_camera: bool) Vec3 {
        return if (relative_to_camera)
            .{
                cos[1] * -sin[0],
                cos[1] * cos[0],
                sin[1],
            }
        else
            .{
                -sin[0],
                cos[0],
                0,
            };
    }

    fn right(sin: Vec2, cos: Vec2) Vec3 {
        return .{
            cos[0],
            sin[0],
            0,
        };
    }

    fn up(sin: Vec2, cos: Vec2, relative_to_camera: bool) Vec3 {
        return if (relative_to_camera)
            .{
                sin[1] * sin[0],
                sin[1] * -cos[0],
                cos[1],
            }
        else
            .{ 0, 0, 1 };
    }

    fn raylib(camera: Camera) c.Camera3D {
        const sin = @sin(camera.rotation);
        const cos = @cos(camera.rotation);
        return .{
            .position = toVector3(camera.position),
            .target = toVector3(camera.position + forward(sin, cos, true)),
            .up = toVector3(up(sin, cos, true)),
            .fovy = camera.options.fovy,
            .projection = c.CAMERA_PERSPECTIVE,
        };
    }

    pub fn rayFromScreen(camera: Camera, screen_position: Vec2) Ray {
        const res = c.GetScreenToWorldRay(
            .{
                .x = screen_position[0],
                .y = screen_position[1],
            },
            camera.raylib(),
        );
        return .{
            .dir = .{
                res.direction.x,
                res.direction.y,
                res.direction.z,
            },
            .pos = .{
                res.position.x,
                res.position.y,
                res.position.z,
            },
        };
    }

    pub fn ray(camera: Camera) Ray {
        const sin = @sin(camera.rotation);
        const cos = @cos(camera.rotation);
        return .{
            .pos = camera.position,
            .dir = forward(sin, cos, true),
        };
    }

    pub fn beginRender(camera: Camera) void {
        c.BeginMode3D(camera.raylib());
    }

    pub fn endRender(camera: Camera) void {
        _ = camera;
        c.EndMode3D();
    }
};

pub fn toVector3(v: Vec3) c.Vector3 {
    return .{ .x = v[0], .y = v[1], .z = v[2] };
}

pub fn toVector2(v: Vec2) c.Vector2 {
    return .{ .x = v[0], .y = v[1] };
}

pub fn fromVector3(v: c.Vector3) Vec3 {
    return .{ v.x, v.y, v.z };
}

pub fn fromVector2(v: c.Vector2) Vec2 {
    return .{ v.x, v.y };
}

pub fn Vector3Rotate(v: c.Vector3, mat: c.Matrix) c.Vector3 {
    const x = v.x;
    const y = v.y;
    const z = v.z;
    return .{
        .x = (((mat.m0 * x) + (mat.m4 * y)) + (mat.m8 * z)),
        .y = (((mat.m1 * x) + (mat.m5 * y)) + (mat.m9 * z)),
        .z = (((mat.m2 * x) + (mat.m6 * y)) + (mat.m10 * z)),
    };
}

pub fn loadVertexBuffer(T: type, data: []T, dynamic: bool) c_uint {
    return c.rlLoadVertexBuffer(data.ptr, @intCast(data.len * @sizeOf(T)), dynamic);
}

pub fn updateVertexBuffer(vboId: c_uint, T: type, data: []T, offset: usize) void {
    c.rlUpdateVertexBuffer(vboId, data.ptr, @intCast(data.len * @sizeOf(T)), @intCast(offset));
}

/// `stride` and `offset` are relative to the `BaseType`
/// `compSize` defines how many elements of `BaseType` go into this attribute
pub fn setVertexAttribute(attribute: c_int, Type: type, stride: usize, offset: usize) void {
    const compSize = switch (@typeInfo(Type)) {
        .vector => |v| v.len,
        else => 1,
    };
    const BaseType = switch (@typeInfo(Type)) {
        .vector => |v| v.child,
        else => Type,
    };
    const typeId = switch (BaseType) {
        f32 => c.RL_FLOAT,
        else => unreachable, // not implemented. if needed add above
    };
    c.rlSetVertexAttribute(@intCast(attribute), @intCast(compSize), typeId, false, @intCast(stride * @sizeOf(BaseType)), @intCast(offset * @sizeOf(BaseType)));
}
