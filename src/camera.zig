const math = @import("std").math;
const c = @import("c.zig");

pub const Camera = struct {
    const Vec3 = @Vector(3, f32);
    const Vec2 = @Vector(2, f32);
    position: Vec3,
    rotation: Vec2 = undefined, // yaw, pitch

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

    pub fn raylib(camera: Camera, options: Options) c.Camera3D {
        const sin = @sin(camera.rotation);
        const cos = @cos(camera.rotation);
        return c.Camera3D{
            .position = c.toVector3(camera.position),
            .target = c.toVector3(camera.position + forward(sin, cos, true)),
            .up = c.toVector3(up(sin, cos, true)),
            .fovy = options.fovy,
            .projection = c.CAMERA_PERSPECTIVE,
        };
    }
};
