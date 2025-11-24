const d = @import("c.zig");
const Bind = d.Input.Digital;
const Allocator = @import("std").mem.Allocator;
const Camera = d.Camera;
const Robot = @import("robot.zig").Type(.{
    .mark_collisions = true,
});
const Part = @import("parts.zig").Part;
const Placement = @import("placement.zig").Placement;
const Color = @import("color.zig").Color;
const Renderer = @import("renderer.zig");

pub const Editor = struct {
    camera: Camera,
    robot: Robot,
    preview: Preview = .{},
    blueprint: ?Part = null,
    cursor: bool = true,
    render_mode: Part.RenderOptions.Mode = .default,
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
            forward: Bind = .{ .key = .w },
            left: Bind = .{ .key = .a },
            back: Bind = .{ .key = .s },
            right: Bind = .{ .key = .d },
            up: Bind = .{ .key = .space },
            down: Bind = .{ .key = .left_shift },
            place: Bind = .{ .mouse = .left },
            remove: Bind = .{ .mouse = .right },
            pick: Bind = .{ .mouse = .middle },
            next_part: Bind = .{ .key = .q },
            next_color: Bind = .{ .key = .c },
            next_render_mode: Bind = .{ .key = .b },
            rotate_ccw: Bind = .{ .key = .r },
            rotate_cw: Bind = .{ .key = .dead },
            mirror: Bind = .{ .key = .x },
            toggle_cursor: Bind = .{ .key = .tab },
        };
    };

    ///undefined camera
    pub fn init(gpa: Allocator, initial_capacity: usize) !Editor {
        return .{
            .camera = undefined,
            .robot = Robot.load("ro.bot", gpa) catch try Robot.init(gpa, initial_capacity),
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
        if (editor.cursor and d.Cursor.hidden()) {
            d.Cursor.enable();
        } else if (!editor.cursor and !d.Cursor.hidden()) {
            d.Cursor.disable();
        }

        if (!editor.cursor) {
            editor.updateCamera(options);
        }

        if (options.binds.next_render_mode.pressed()) {
            editor.render_mode = @enumFromInt(@mod(@intFromEnum(editor.render_mode) +% 1, @typeInfo(Part.RenderOptions.Mode).@"enum".fields.len));
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
        const frame_time = d.Fps.frameTime();
        var movement: @Vector(3, f32) = @splat(0);
        if (options.binds.forward.isDown()) movement += .{ 0, 1, 0 };
        if (options.binds.left.isDown()) movement += .{ -1, 0, 0 };
        if (options.binds.back.isDown()) movement += .{ 0, -1, 0 };
        if (options.binds.right.isDown()) movement += .{ 1, 0, 0 };
        if (options.binds.up.isDown()) movement += .{ 0, 0, 1 };
        if (options.binds.down.isDown()) movement += .{ 0, 0, -1 };
        movement *= @splat(options.speed * frame_time);
        var rotation: d.Vec2 = .{
            d.Input.Analog.Mouse.right.value(),
            d.Input.Analog.Mouse.forward.value(),
        };
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
        if (d.Input.Analog.Mouse.wheel.value() > 0 or options.binds.rotate_cw.pressed()) {
            editor.preview.rotation = editor.preview.rotation.rotate(Placement.Rotation.z270);
        }
        if (d.Input.Analog.Mouse.wheel.value() < 0 or options.binds.rotate_ccw.pressed()) {
            editor.preview.rotation = editor.preview.rotation.rotate(Placement.Rotation.z90);
        }

        const ray: d.Ray =
            if (editor.cursor)
                editor.camera.rayFromScreen(d.Window.mousePosition())
            else
                editor.camera.ray();
        const ray_result = editor.robot.rayCollision(ray);
        editor.preview.target = ray_result.part_index;

        editor.preview.placement = _: {
            if (ray_result.connection) |connection| {
                break :_ (connection.place(editor.preview.rotation) catch break :_ null)
                    .place(editor.preview.part.connections()[0].inv()) catch break :_ null;
            } else {
                break :_ null;
            }
        };

        if (editor.preview.evalNeeded(preview_old)) {
            editor.preview.collides = editor.robot.buildCollision(editor.preview.part, editor.preview.placement);
        }
    }

    pub fn render(editor: Editor) void {
        { // 3d
            editor.camera.beginRender();
            defer editor.camera.endRender();
            editor.robot.render(editor.render_mode);
            if (editor.preview.placement) |placement|
                editor.preview.part.render(
                    placement,
                    if (editor.preview.collides)
                        Color.collision
                    else
                        editor.preview.color.rgba(),
                    .{
                        .mode = editor.render_mode,
                        .preview = true,
                    },
                );
            if (editor.blueprint) |part| part.blueprint();
            Renderer.drawBuffer();
        }
        //overlay
        if (!editor.cursor) editor.crosshair();
    }

    fn crosshair(editor: Editor) void {
        const V = d.Vec2;
        const size_h = V{ 11, 1 };
        const size_v = @shuffle(f32, size_h, undefined, @Vector(2, i32){ 1, 0 });
        const border = 1;
        const color = if (editor.preview.collides) Color.collision else Color.black.rgba();
        const border_color = d.Color.white;
        const center = V{ @floatFromInt(d.Window.width()), @floatFromInt(d.Window.height()) } * @as(V, @splat(0.5));
        const size_border_h = size_h + @as(V, @splat(border * 2));
        const size_border_v = size_v + @as(V, @splat(border * 2));

        d.Window.Draw.rect(
            center - size_border_h * @as(V, @splat(0.5)),
            size_border_h,
            border_color,
        );
        d.Window.Draw.rect(
            center - size_border_v * @as(V, @splat(0.5)),
            size_border_v,
            border_color,
        );
        d.Window.Draw.rect(
            center - size_h * @as(V, @splat(0.5)),
            size_h,
            color,
        );
        d.Window.Draw.rect(
            center - size_v * @as(V, @splat(0.5)),
            size_v,
            color,
        );
    }
};
