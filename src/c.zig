const std = @import("std");
const math = std.math;

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
    pub fn init(width_: usize, height_: usize, title: [*c]const u8) !void {
        c.InitWindow(@intCast(width_), @intCast(height_), title);
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

    pub fn width() usize {
        return @intCast(c.GetRenderWidth());
    }

    pub fn height() usize {
        return @intCast(c.GetRenderHeight());
    }

    pub const Draw = struct {
        pub fn begin() void {
            c.BeginDrawing();
        }

        pub fn end() void {
            c.EndDrawing();
        }

        pub fn rect(position: Vec2, size: Vec2, color: Color) void {
            c.DrawRectangleV(
                toVector2(position),
                toVector2(size),
                color.toRaylib(),
            );
        }

        pub fn text(text_: [*c]const u8, posX: f32, posY: f32, fontSize: f32, color: Color) void {
            c.DrawText(text_, @intFromFloat(posX), @intFromFloat(posY), @intFromFloat(fontSize), color.toRaylib());
        }

        pub fn clear(color: Color) void {
            c.ClearBackground(color.toRaylib());
        }
    };
};

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8 = 255,

    pub const lightgray = fromRaylib(c.LIGHTGRAY);
    pub const gray = fromRaylib(c.GRAY);
    pub const darkgray = fromRaylib(c.DARKGRAY);
    pub const yellow = fromRaylib(c.YELLOW);
    pub const gold = fromRaylib(c.GOLD);
    pub const orange = fromRaylib(c.ORANGE);
    pub const pink = fromRaylib(c.PINK);
    pub const red = fromRaylib(c.RED);
    pub const maroon = fromRaylib(c.MAROON);
    pub const lime = fromRaylib(c.GREEN);
    pub const green = fromRaylib(c.LIME);
    pub const darkgreen = fromRaylib(c.DARKGREEN);
    pub const lightblue = fromRaylib(c.SKYBLUE);
    pub const blue = fromRaylib(c.BLUE);
    pub const darkblue = fromRaylib(c.DARKBLUE);
    pub const purple = fromRaylib(c.PURPLE);
    pub const violet = fromRaylib(c.VIOLET);
    pub const darkpurple = fromRaylib(c.DARKPURPLE);
    pub const beige = fromRaylib(c.BEIGE);
    pub const brown = fromRaylib(c.BROWN);
    pub const darkbrown = fromRaylib(c.DARKBROWN);
    pub const white = fromRaylib(c.WHITE);
    pub const black = fromRaylib(c.BLACK);
    pub const clear = fromRaylib(c.BLANK);
    pub const magenta = fromRaylib(c.MAGENTA);
    pub const raywhite = fromRaylib(c.RAYWHITE);

    pub fn alpha(color: Color, alpha_: f32) Color {
        var res = color;
        res.a = @intFromFloat(@as(f32, @floatFromInt(res.a)) * alpha_);
        return res;
    }

    fn toRaylib(color: Color) c.Color {
        return .{
            .r = color.r,
            .g = color.g,
            .b = color.b,
            .a = color.a,
        };
    }

    fn fromRaylib(color: c.Color) Color {
        return .{
            .r = color.r,
            .g = color.g,
            .b = color.b,
            .a = color.a,
        };
    }
};

pub const Fps = struct {
    pub fn get() usize {
        return @intCast(c.GetFPS());
    }

    pub fn frameTime() f32 {
        return c.GetFrameTime();
    }

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

pub const Cursor = struct {
    pub fn hidden() bool {
        return c.IsCursorHidden();
    }

    pub fn enable() void {
        c.EnableCursor();
    }

    pub fn disable() void {
        c.DisableCursor();
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

    pub fn boundingBox(ray: Ray, boundingBox_: BoundingBox) ?Hit {
        // pos + t_0 * dir = min
        // pos + t_1 * dir = max
        const t_0 = (boundingBox_.min - ray.pos) / ray.dir;
        const t_1 = (boundingBox_.max - ray.pos) / ray.dir;

        const t_min = @min(t_0, t_1);
        const t_max = @max(t_0, t_1);

        const enter = @reduce(.Max, t_min);
        const exit = @reduce(.Min, t_max);
        if (exit < enter) return null;
        if (exit <= 0) return null;
        const t_: Vec3 = @splat(enter);
        const one: Vec3 = @splat(1);
        const zero: Vec3 = @splat(0);
        return .{
            .dist = enter,
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

pub const Input = struct {
    pub const Digital = union(enum) {
        key: Key,
        mouse: Mouse,

        pub fn pressed(di: Digital) bool {
            return switch (di) {
                .key => |k| k.pressed(),
                .mouse => |m| m.pressed(),
            };
        }

        pub fn isDown(di: Digital) bool {
            return switch (di) {
                .key => |k| k.isDown(),
                .mouse => |m| m.isDown(),
            };
        }

        pub fn released(di: Digital) bool {
            return switch (di) {
                .key => |k| k.released(),
                .mouse => |m| m.released(),
            };
        }

        pub const Key = enum(c_int) {
            pub fn pressed(key: Key) bool {
                return c.IsKeyPressed(@intFromEnum(key));
            }

            pub fn isDown(key: Key) bool {
                return c.IsKeyDown(@intFromEnum(key));
            }

            pub fn released(key: Key) bool {
                return c.IsKeyReleased(@intFromEnum(key));
            }

            dead = c.KEY_NULL,
            apostrophe = c.KEY_APOSTROPHE,
            comma = c.KEY_COMMA,
            minus = c.KEY_MINUS,
            period = c.KEY_PERIOD,
            slash = c.KEY_SLASH,
            zero = c.KEY_ZERO,
            one = c.KEY_ONE,
            two = c.KEY_TWO,
            three = c.KEY_THREE,
            four = c.KEY_FOUR,
            five = c.KEY_FIVE,
            six = c.KEY_SIX,
            seven = c.KEY_SEVEN,
            eight = c.KEY_EIGHT,
            nine = c.KEY_NINE,
            semicolon = c.KEY_SEMICOLON,
            equal = c.KEY_EQUAL,
            a = c.KEY_A,
            b = c.KEY_B,
            c = c.KEY_C,
            d = c.KEY_D,
            e = c.KEY_E,
            f = c.KEY_F,
            g = c.KEY_G,
            h = c.KEY_H,
            i = c.KEY_I,
            j = c.KEY_J,
            k = c.KEY_K,
            l = c.KEY_L,
            m = c.KEY_M,
            n = c.KEY_N,
            o = c.KEY_O,
            p = c.KEY_P,
            q = c.KEY_Q,
            r = c.KEY_R,
            s = c.KEY_S,
            t = c.KEY_T,
            u = c.KEY_U,
            v = c.KEY_V,
            w = c.KEY_W,
            x = c.KEY_X,
            y = c.KEY_Y,
            z = c.KEY_Z,
            left_bracket = c.KEY_LEFT_BRACKET,
            backslash = c.KEY_BACKSLASH,
            right_bracket = c.KEY_RIGHT_BRACKET,
            grave = c.KEY_GRAVE,
            space = c.KEY_SPACE,
            escape = c.KEY_ESCAPE,
            enter = c.KEY_ENTER,
            tab = c.KEY_TAB,
            backspace = c.KEY_BACKSPACE,
            insert = c.KEY_INSERT,
            delete = c.KEY_DELETE,
            right = c.KEY_RIGHT,
            left = c.KEY_LEFT,
            down = c.KEY_DOWN,
            up = c.KEY_UP,
            page_up = c.KEY_PAGE_UP,
            page_down = c.KEY_PAGE_DOWN,
            home = c.KEY_HOME,
            key_end = c.KEY_END,
            caps_lock = c.KEY_CAPS_LOCK,
            scroll_lock = c.KEY_SCROLL_LOCK,
            num_lock = c.KEY_NUM_LOCK,
            print_screen = c.KEY_PRINT_SCREEN,
            pause = c.KEY_PAUSE,
            f1 = c.KEY_F1,
            f2 = c.KEY_F2,
            f3 = c.KEY_F3,
            f4 = c.KEY_F4,
            f5 = c.KEY_F5,
            f6 = c.KEY_F6,
            f7 = c.KEY_F7,
            f8 = c.KEY_F8,
            f9 = c.KEY_F9,
            f10 = c.KEY_F10,
            f11 = c.KEY_F11,
            f12 = c.KEY_F12,
            left_shift = c.KEY_LEFT_SHIFT,
            left_control = c.KEY_LEFT_CONTROL,
            left_alt = c.KEY_LEFT_ALT,
            left_super = c.KEY_LEFT_SUPER,
            right_shift = c.KEY_RIGHT_SHIFT,
            right_control = c.KEY_RIGHT_CONTROL,
            right_alt = c.KEY_RIGHT_ALT,
            right_super = c.KEY_RIGHT_SUPER,
            kb_menu = c.KEY_KB_MENU,
            keypad_0 = c.KEY_KP_0,
            keypad_1 = c.KEY_KP_1,
            keypad_2 = c.KEY_KP_2,
            keypad_3 = c.KEY_KP_3,
            keypad_4 = c.KEY_KP_4,
            keypad_5 = c.KEY_KP_5,
            keypad_6 = c.KEY_KP_6,
            keypad_7 = c.KEY_KP_7,
            keypad_8 = c.KEY_KP_8,
            keypad_9 = c.KEY_KP_9,
            keypad_decimal = c.KEY_KP_DECIMAL,
            keypad_divide = c.KEY_KP_DIVIDE,
            keypad_multiply = c.KEY_KP_MULTIPLY,
            keypad_substract = c.KEY_KP_SUBTRACT,
            keypad_add = c.KEY_KP_ADD,
            keypad_enter = c.KEY_KP_ENTER,
            keypad_equal = c.KEY_KP_EQUAL,
            back = c.KEY_BACK,
            menu = c.KEY_MENU,
            volumne_up = c.KEY_VOLUME_UP,
            volumne_down = c.KEY_VOLUME_DOWN,
        };

        pub const Mouse = enum(c_int) {
            pub fn pressed(mouse: Mouse) bool {
                return c.IsMouseButtonPressed(@intFromEnum(mouse));
            }

            pub fn isDown(mouse: Mouse) bool {
                return c.IsMouseButtonDown(@intFromEnum(mouse));
            }

            pub fn released(mouse: Mouse) bool {
                return c.IsMouseButtonReleased(@intFromEnum(mouse));
            }

            back = c.MOUSE_BUTTON_BACK,
            extra = c.MOUSE_BUTTON_EXTRA,
            forward = c.MOUSE_BUTTON_FORWARD,
            left = c.MOUSE_BUTTON_LEFT,
            middle = c.MOUSE_BUTTON_MIDDLE,
            right = c.MOUSE_BUTTON_RIGHT,
            side = c.MOUSE_BUTTON_SIDE,
        };
    };

    pub const Analog = union(enum) {
        mouse: Mouse,

        pub fn value(an: Analog) f32 {
            return switch (an) {
                .mouse => |m| m.value(),
            };
        }

        pub const Mouse = enum {
            pub fn value(mouse: Mouse) f32 {
                return switch (mouse) {
                    .wheel => c.GetMouseWheelMove(),
                    .right => c.GetMouseDelta().x,
                    .forward => c.GetMouseDelta().y,
                };
            }

            wheel,
            right,
            forward,
        };
    };
};

pub const Gui = struct {
    pub fn button(rect: c.Rectangle, text: [*c]const u8) bool {
        return c.GuiButton(rect, text) == 1;
    }

    pub fn enable() void {
        c.GuiEnable();
    }

    pub fn disable() void {
        c.GuiDisable();
    }

    pub fn panel(rect: c.Rectangle, text: [*c]const u8) void {
        _ = c.GuiPanel(rect, text);
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
