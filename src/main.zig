const std = @import("std");
const c = @import("c.zig");
const misc = @import("misc.zig");
const vec = misc.vec;
const Parts = @import("parts.zig");
const Placement = @import("placement.zig").Placement;
const Robot = @import("robot.zig").Robot;
const Camera = @import("camera.zig").Camera;

var camera: Camera = undefined;
var fovy: f32 = 45;
var gpa = std.heap.DebugAllocator(.{}){};
var allocator = gpa.allocator();
var selected_part = Parts.Part.cube;
var robot: Robot = undefined;
var preview: ?Placement = null;
var placement_modifier = Placement{
    .position = .{ 0, 0, -1 },
    .rotation = Placement.Rotation.up,
};
var color = c.BEIGE;
var part = Parts.Part.cube;

pub fn main() !void {
    try init();
    defer deinit();

    //main loop
    while (!c.WindowShouldClose()) {
        //update
        if (c.IsKeyPressed(c.KEY_TAB)) {
            if (c.IsCursorHidden())
                c.EnableCursor()
            else
                c.DisableCursor();
        }
        if (c.IsKeyPressed(c.KEY_Q)) {
            part = @enumFromInt(@mod(@intFromEnum(part) +% 1, @typeInfo(Parts.Part).@"enum".fields.len));
        }
        if (c.IsCursorHidden()) {
            updateCamera();
        }

        const ray: c.Ray =
            if (c.IsCursorHidden())
                misc.CameraRay(camera.raylib(fovy))
            else
                c.GetScreenToWorldRay(c.GetMousePosition(), camera.raylib(fovy));
        const ray_result = robot.rayCollision(ray);
        const part_index = ray_result.part_index;
        preview = ray_result.connection;
        if (preview) |connection| {
            preview = connection.place(placement_modifier)
                .place(selected_part.connections()[0].inv());
        }

        if (c.IsMouseButtonPressed(c.MOUSE_BUTTON_LEFT)) {
            if (preview) |p|
                try robot.add(p, part, color);
        }
        if (c.IsMouseButtonPressed(c.MOUSE_BUTTON_RIGHT)) {
            if (part_index) |index| {
                robot.remove(index);
            }
        }
        if (c.IsMouseButtonPressed(c.MOUSE_BUTTON_MIDDLE)) {
            placement_modifier = placement_modifier.rotate(Placement.Rotation.mirror);
        }
        if (c.GetMouseWheelMove() > 0) {
            placement_modifier = placement_modifier.rotate(Placement.Rotation.z270);
        }
        if (c.GetMouseWheelMove() < 0) {
            placement_modifier = placement_modifier.rotate(Placement.Rotation.z90);
        }
        if (c.IsKeyDown('Z')) {
            c.DrawText(c.GetKeyName('Z'), 100, 100, 10, c.BLACK);
        }

        c.DrawFPS(10, 10);

        //render
        render();
    }
}

fn init() !void {
    c.InitWindow(1280, 720, "hello world");
    //c.DisableCursor();
    c.SetTargetFPS(60);
    camera = .{ .position = .{ 10, 10, 10 } };
    camera.target(.{ 0, 0, 0 });
    Parts.loadAssets();
    robot = try Robot.init(allocator, 2000);
}

fn render() void {
    c.BeginDrawing();
    defer c.EndDrawing();
    c.ClearBackground(c.RAYWHITE);
    c.BeginMode3D(camera.raylib(fovy));
    defer c.EndMode3D();
    robot.render();
    if (preview) |p| part.render(p, c.BLACK, true);
}

fn deinit() void {
    robot.deinit();
    if (gpa.deinit() == .leak) @panic("TEST FAIL");
    c.CloseWindow();
}

fn updateCamera() void {
    const speed = 5.4;
    const sensitivity = -0.1;
    const frame_time = c.GetFrameTime();
    var movement: @Vector(3, f32) = @splat(0);
    if (c.IsKeyDown(c.KEY_W)) movement += .{ 0, 1, 0 };
    if (c.IsKeyDown(c.KEY_A)) movement += .{ -1, 0, 0 };
    if (c.IsKeyDown(c.KEY_S)) movement += .{ 0, -1, 0 };
    if (c.IsKeyDown(c.KEY_D)) movement += .{ 1, 0, 0 };
    if (c.IsKeyDown(c.KEY_SPACE)) movement += .{ 0, 0, 1 };
    if (c.IsKeyDown(c.KEY_LEFT_CONTROL)) movement += .{ 0, 0, -1 };
    movement *= @splat(speed * frame_time);
    var rotation = misc.fromVec2(c.GetMouseDelta());
    rotation *= @splat(sensitivity * frame_time);

    camera.update(movement, rotation, .{});
}
