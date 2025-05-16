const std = @import("std");
const c = @import("c.zig");
const misc = @import("misc.zig");
const vec = misc.vec;
const Parts = @import("parts.zig");
const Placement = @import("placement.zig").Placement;
const Robot = @import("robot.zig").Robot;

var camera: c.Camera3D = undefined;
var gpa = std.heap.DebugAllocator(.{}){};
var allocator = gpa.allocator();
var selected_part = Parts.Part.cube;
var robot: Robot = undefined;
var preview: ?Placement = null;

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
        if (c.IsCursorHidden()) {
            c.UpdateCamera(&camera, c.CAMERA_FREE);
        }

        const ray: c.Ray =
            if (c.IsCursorHidden())
                misc.CameraRay(camera)
            else
                c.GetScreenToWorldRay(c.GetMousePosition(), camera);

        const part_index, preview = robot.rayCollision(ray);
        if (preview) |connection| {
            preview = connection
                .place(.{ .position = .{ 0, 0, -1 }, .rotation = Placement.Rotation.up })
                .place(selected_part.connections()[0].inv());
        }

        if (c.IsMouseButtonPressed(c.MOUSE_BUTTON_LEFT)) {
            if (preview) |p|
                try robot.add(p, .cube, c.BEIGE);
        }
        if (c.IsMouseButtonPressed(c.MOUSE_BUTTON_RIGHT)) {
            if (part_index) |index| {
                robot.remove(index);
            }
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
    //c.SetTargetFPS(60);
    camera = .{
        .position = vec(10, 10, 10),
        .target = vec(0, 0, 0),
        .up = vec(0, 0, 1),
        .fovy = 45.0,
        .projection = c.CAMERA_PERSPECTIVE,
    };
    Parts.loadAssets();
    robot = try Robot.init(allocator, 2000);
}

fn render() void {
    c.BeginDrawing();
    defer c.EndDrawing();
    c.ClearBackground(c.RAYWHITE);
    c.BeginMode3D(camera);
    defer c.EndMode3D();
    robot.render();
    if (preview) |p| Parts.Part.cube.render(p, c.BLACK, true);
}

fn deinit() void {
    robot.deinit();
    if (gpa.deinit() == .leak) @panic("TEST FAIL");
    c.CloseWindow();
}
