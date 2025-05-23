const std = @import("std");
const c = @import("c.zig");
const misc = @import("misc.zig");
const vec = misc.vec;
const parts = @import("parts.zig");
const Placement = @import("placement.zig").Placement;
const Robot = @import("robot.zig").RobotType(true);
const Camera = @import("camera.zig").Camera;
const Options = @import("options.zig").Options;

var camera: Camera = undefined;
var options: Options = .{};
var gpa = std.heap.DebugAllocator(.{}){};
var allocator = gpa.allocator();
var selected_part = parts.Part.cube;
var robot: Robot = undefined;
var preview: ?Placement = null;
var preview_old: ?Placement = null;
var preview_collides: bool = false;
var placement_modifier = Placement{
    .position = .{ 0, 0, -1 },
    .rotation = Placement.Rotation.up,
};
var color = c.BEIGE;

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
            selected_part = @enumFromInt(@mod(@intFromEnum(selected_part) +% 1, @typeInfo(parts.Part).@"enum".fields.len));
        }
        if (c.IsCursorHidden()) {
            updateCamera();
        }

        const ray: c.Ray =
            if (c.IsCursorHidden())
                c.CameraRay(camera.raylib(options.camera))
            else
                c.GetScreenToWorldRay(c.GetMousePosition(), camera.raylib(options.camera));
        const ray_result = robot.rayCollision(ray);
        const part_index = ray_result.part_index;
        preview = ray_result.connection;
        if (preview) |connection| {
            preview = connection.place(placement_modifier)
                .place(selected_part.connections()[0].inv());
        }
        if (preview != preview_old) {
            preview_old = preview;
            preview_collides = robot.buildCollision(selected_part, preview);
        }

        if (c.IsMouseButtonPressed(c.MOUSE_BUTTON_LEFT)) {
            if (preview) |p|
                if (!preview_collides)
                    try robot.add(p, selected_part, color);
        }
        if (c.IsMouseButtonPressed(c.MOUSE_BUTTON_RIGHT)) {
            if (part_index) |index| {
                robot.remove(index);
            }
        }
        if (c.IsMouseButtonPressed(c.MOUSE_BUTTON_MIDDLE)) {
            if (part_index) |index| {
                const target = robot.at(index);
                selected_part = target.part;
                color = target.color;
            }
        }
        if (c.GetMouseWheelMove() > 0 or c.IsKeyPressed(c.KEY_R)) {
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
    const monitor_id = c.GetCurrentMonitor();
    const monitor_refresh_rate = c.GetMonitorRefreshRate(monitor_id);
    c.SetTargetFPS(monitor_refresh_rate);
    camera = .{ .position = .{ 10, 10, 10 } };
    camera.target(.{ 0, 0, 0 });
    parts.loadAssets();
    robot = try Robot.init(allocator, 2000);
}

fn render() void {
    c.BeginDrawing();
    defer c.EndDrawing();
    c.ClearBackground(c.RAYWHITE);
    c.BeginMode3D(camera.raylib(options.camera));
    defer c.EndMode3D();
    robot.render();
    if (preview) |p| selected_part.render(p, c.BLACK, true);
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
    var rotation = c.fromVec2(c.GetMouseDelta());
    rotation *= @splat(sensitivity * frame_time);

    camera.update(movement, rotation, .{});
}
