const c = @import("c.zig");
const Allocator = @import("std").mem.Allocator;
const Bind = @import("bind.zig").Bind;
const Camera = @import("camera.zig").Camera;
const Robot = @import("robot.zig").Type(.{
    .mark_collisions = true,
});
const Part = @import("parts.zig").Part;
const Placement = @import("placement.zig").Placement;
const Color = @import("color.zig").Color;

pub const Editor = struct {
    camera: Camera,
    robot: Robot,
    preview: Preview = .{},
    blueprint: ?Part = null,
    cursor: bool = true,
    gpa: Allocator,

    const Preview = struct {
        rotation: Placement = Placement.connection,
        placement: ?Placement = null,
        target: ?usize = null,
        part: Part = .cube,
        color: Color = .white,
        collides: bool = false,

        fn evalNeeded(new: Preview, old: Preview) bool {
            return new.placement != old.placement or new.part != old.part;
        }
    };

    pub const Options = struct {
        speed: f32 = 5.4,
        sensitivity: f32 = -0.0015,
        camera: Camera.Options = .{},
        binds: Binds = .{},

        pub const Binds = struct {
            forward: Bind = .{ .key = c.KEY_W },
            left: Bind = .{ .key = c.KEY_A },
            back: Bind = .{ .key = c.KEY_S },
            right: Bind = .{ .key = c.KEY_D },
            up: Bind = .{ .key = c.KEY_SPACE },
            down: Bind = .{ .key = c.KEY_LEFT_CONTROL },
            place: Bind = .{ .mouse = c.MOUSE_BUTTON_LEFT },
            remove: Bind = .{ .mouse = c.MOUSE_BUTTON_RIGHT },
            pick: Bind = .{ .mouse = c.MOUSE_BUTTON_MIDDLE },
            next_part: Bind = .{ .key = c.KEY_Q },
            next_color: Bind = .{ .key = c.KEY_C },
            rotate_ccw: Bind = .{ .key = c.KEY_R },
            rotate_cw: Bind = .{},
            mirror: Bind = .{ .key = c.KEY_X },
            toggle_cursor: Bind = .{ .key = c.KEY_TAB },
        };
    };

    ///undefined camera
    pub fn init(gpa: Allocator, initial_capacity: usize) !Editor {
        return .{
            .camera = undefined,
            .robot = Robot.load(gpa) catch try Robot.init(gpa, initial_capacity),
            .gpa = gpa,
        };
    }

    pub fn deinit(editor: *Editor) void {
        editor.robot.save() catch {};
        editor.robot.deinit(editor.gpa);
    }

    pub fn update(editor: *Editor, options: Options) !void {
        if (options.binds.toggle_cursor.pressed()) {
            editor.cursor = !editor.cursor;
        }
        if (editor.cursor and c.IsCursorHidden()) {
            c.EnableCursor();
        } else if (!editor.cursor and !c.IsCursorHidden()) {
            c.DisableCursor();
        }

        if (!editor.cursor) {
            editor.updateCamera(options);
        }

        editor.updatePreview(options);

        if (options.binds.place.pressed()) {
            if (editor.preview.placement) |placement|
                if (!editor.preview.collides)
                    try editor.robot.add(editor.gpa, placement, editor.preview.part, editor.preview.color);
        }
        if (options.binds.remove.pressed()) {
            if (editor.preview.target) |index| {
                editor.robot.remove(index);
            }
        }
        if (options.binds.pick.pressed()) {
            if (editor.preview.target) |index| {
                const target = editor.robot.at(index);
                editor.preview.part = target.part;
                editor.preview.color = target.color;
            }
        }
    }

    fn updateCamera(editor: *Editor, options: Options) void {
        const frame_time = c.GetFrameTime();
        var movement: @Vector(3, f32) = @splat(0);
        if (options.binds.forward.down()) movement += .{ 0, 1, 0 };
        if (options.binds.left.down()) movement += .{ -1, 0, 0 };
        if (options.binds.back.down()) movement += .{ 0, -1, 0 };
        if (options.binds.right.down()) movement += .{ 1, 0, 0 };
        if (options.binds.up.down()) movement += .{ 0, 0, 1 };
        if (options.binds.down.down()) movement += .{ 0, 0, -1 };
        movement *= @splat(options.speed * frame_time);
        var rotation = c.fromVector2(c.GetMouseDelta());
        rotation *= @splat(options.sensitivity);
        editor.camera.update(movement, rotation, .{});
    }

    /// returns part_index of target part
    fn updatePreview(editor: *Editor, options: Options) void {
        const preview_old = editor.preview;

        if (options.binds.next_part.pressed()) {
            editor.preview.part = @enumFromInt(@mod(@intFromEnum(editor.preview.part) +% 1, @typeInfo(Part).@"enum".fields.len));
        }
        if (options.binds.next_color.pressed()) {
            editor.preview.color = @enumFromInt(@mod(@intFromEnum(editor.preview.color) +% 1, @typeInfo(Color).@"enum".fields.len));
        }
        if (options.binds.mirror.pressed()) {
            editor.preview.rotation = editor.preview.rotation.rotate(Placement.Rotation.mirror);
        }
        if (c.GetMouseWheelMove() > 0 or options.binds.rotate_cw.pressed()) {
            editor.preview.rotation = editor.preview.rotation.rotate(Placement.Rotation.z270);
        }
        if (c.GetMouseWheelMove() < 0 or options.binds.rotate_ccw.pressed()) {
            editor.preview.rotation = editor.preview.rotation.rotate(Placement.Rotation.z90);
        }

        const ray: c.Ray =
            if (editor.cursor)
                c.GetScreenToWorldRay(c.GetMousePosition(), editor.camera.raylib(options.camera))
            else
                c.CameraRay(editor.camera.raylib(options.camera));
        const ray_result = editor.robot.rayCollision(ray);
        editor.preview.target = ray_result.part_index;
        if (ray_result.connection) |connection| {
            editor.preview.placement = connection.place(editor.preview.rotation)
                .place(editor.preview.part.connections()[0].inv());
        } else {
            editor.preview.placement = null;
        }

        if (editor.preview.evalNeeded(preview_old)) {
            editor.preview.collides = editor.robot.buildCollision(editor.preview.part, editor.preview.placement);
        }
    }

    pub fn render(editor: Editor, options: Options) void {
        {
            c.BeginMode3D(editor.camera.raylib(options.camera));
            defer c.EndMode3D();
            editor.robot.render();
            if (editor.preview.placement) |placement|
                editor.preview.part.render(
                    placement,
                    if (editor.preview.collides)
                        Color.collision
                    else
                        editor.preview.color.raylib(),
                    true,
                );
            if (editor.blueprint) |part| part.blueprint();
        }
        //overlay
        if (!editor.cursor) editor.crosshair();
    }

    fn crosshair(editor: Editor) void {
        const V = @Vector(2, f32);
        const size_h = V{ 11, 1 };
        const size_v = @shuffle(f32, size_h, undefined, @Vector(2, i32){ 1, 0 });
        const border = 1;
        const color = if (editor.preview.collides) Color.collision else c.BLACK;
        const border_color = c.WHITE;
        const center = V{ @floatFromInt(c.GetRenderWidth()), @floatFromInt(c.GetRenderHeight()) } * @as(V, @splat(0.5));
        const size_border_h = size_h + @as(V, @splat(border * 2));
        const size_border_v = size_v + @as(V, @splat(border * 2));

        c.DrawRectangleV(
            c.toVector2(center - size_border_h * @as(V, @splat(0.5))),
            c.toVector2(size_border_h),
            border_color,
        );
        c.DrawRectangleV(
            c.toVector2(center - size_border_v * @as(V, @splat(0.5))),
            c.toVector2(size_border_v),
            border_color,
        );
        c.DrawRectangleV(
            c.toVector2(center - size_h * @as(V, @splat(0.5))),
            c.toVector2(size_h),
            color,
        );
        c.DrawRectangleV(
            c.toVector2(center - size_v * @as(V, @splat(0.5))),
            c.toVector2(size_v),
            color,
        );
    }
};
