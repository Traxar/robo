const o = @import("o.zig");
const DigitalInput = o.input.Digital;
const Allocator = @import("std").mem.Allocator;
const Camera = o.Camera;
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
        controls: Controls = .{},

        pub const Controls = struct {
            forward: DigitalInput = .{ .key = .w },
            left: DigitalInput = .{ .key = .a },
            back: DigitalInput = .{ .key = .s },
            right: DigitalInput = .{ .key = .d },
            up: DigitalInput = .{ .key = .space },
            down: DigitalInput = .{ .key = .left_shift },
            place: DigitalInput = .{ .mouse = .left },
            remove: DigitalInput = .{ .mouse = .right },
            pick: DigitalInput = .{ .mouse = .middle },
            next_part: DigitalInput = .{ .key = .q },
            next_color: DigitalInput = .{ .key = .c },
            next_render_mode: DigitalInput = .{ .key = .b },
            rotate_ccw: DigitalInput = .{ .key = .r },
            rotate_cw: DigitalInput = .{ .key = .dead },
            mirror: DigitalInput = .{ .key = .x },
            toggle_cursor: DigitalInput = .{ .key = .tab },
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

    pub fn update(editor: *Editor, dt: f32, options: Options) !void {
        if (options.controls.toggle_cursor.pressed()) {
            editor.cursor = !editor.cursor;
        }
        if (editor.cursor and o.cursor.hidden()) {
            o.cursor.enable();
        } else if (!editor.cursor and !o.cursor.hidden()) {
            o.cursor.disable();
        }

        if (!editor.cursor) {
            editor.updateCamera(dt, options);
        }

        if (options.controls.next_render_mode.pressed()) {
            editor.render_mode = @enumFromInt(@mod(@intFromEnum(editor.render_mode) +% 1, @typeInfo(Part.RenderOptions.Mode).@"enum".fields.len));
        }

        editor.updatePreview(options);

        if (options.controls.place.pressed()) {
            if (editor.preview.placement) |placement|
                if (!editor.preview.collides)
                    try editor.robot.add(editor.gpa, placement, editor.preview.part, editor.preview.color);
        }
        if (options.controls.remove.pressed()) {
            if (editor.preview.target) |index| {
                editor.robot.remove(index);
            }
        }
        if (options.controls.pick.pressed()) {
            if (editor.preview.target) |index| {
                const target = editor.robot.at(index);
                editor.preview.part = target.part;
                editor.preview.color = target.color;
            }
        }
    }

    fn updateCamera(editor: *Editor, dt: f32, options: Options) void {
        var movement: @Vector(3, f32) = @splat(0);
        if (options.controls.forward.isDown()) movement += .{ 0, 1, 0 };
        if (options.controls.left.isDown()) movement += .{ -1, 0, 0 };
        if (options.controls.back.isDown()) movement += .{ 0, -1, 0 };
        if (options.controls.right.isDown()) movement += .{ 1, 0, 0 };
        if (options.controls.up.isDown()) movement += .{ 0, 0, 1 };
        if (options.controls.down.isDown()) movement += .{ 0, 0, -1 };
        movement *= @splat(options.speed * dt);
        var rotation = o.input.Analog.Mouse.move.value();
        rotation *= @splat(options.sensitivity);
        editor.camera.update(movement, rotation, .{});
    }

    /// returns part_index of target part
    fn updatePreview(editor: *Editor, options: Options) void {
        const preview_old = editor.preview;

        if (options.controls.next_part.pressed()) {
            editor.preview.part = @enumFromInt(@mod(@intFromEnum(editor.preview.part) +% 1, @typeInfo(Part).@"enum".fields.len));
        }
        if (options.controls.next_color.pressed()) {
            editor.preview.color = @enumFromInt(@mod(@intFromEnum(editor.preview.color) +% 1, @typeInfo(Color).@"enum".fields.len));
        }
        if (options.controls.mirror.pressed()) {
            editor.preview.rotation = editor.preview.rotation.rotate(Placement.Rotation.mirror);
        }
        const wheel = o.input.Analog.Mouse.wheel.value();

        if (wheel[1] > 0 or options.controls.rotate_cw.pressed()) {
            editor.preview.rotation = editor.preview.rotation.rotate(Placement.Rotation.z270);
        }
        if (wheel[1] < 0 or options.controls.rotate_ccw.pressed()) {
            editor.preview.rotation = editor.preview.rotation.rotate(Placement.Rotation.z90);
        }

        const ray: o.Ray =
            if (editor.cursor)
                editor.camera.rayFromScreen(o.window.mousePosition())
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
            o.render.begin(editor.camera);
            defer o.render.end();
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
        const V = @Vector(2, f32);
        const size_h = V{ 11, 1 } * @as(V, @splat(0.5));
        const size_v = @shuffle(f32, size_h, undefined, @Vector(2, i32){ 1, 0 });
        const border = 1;
        const color = if (editor.preview.collides) Color.collision else Color.black.rgba();
        const border_color = o.Color.white;
        const center = o.draw.size() * @as(V, @splat(0.5));
        const size_border_h = size_h + @as(V, @splat(border));
        const size_border_v = size_v + @as(V, @splat(border));

        o.draw.rect(
            .{
                .min = center - size_border_h,
                .max = center + size_border_h,
            },
            border_color,
        );
        o.draw.rect(
            .{
                .min = center - size_border_v,
                .max = center + size_border_v,
            },
            border_color,
        );
        o.draw.rect(
            .{
                .min = center - size_h,
                .max = center + size_h,
            },
            color,
        );
        o.draw.rect(
            .{
                .min = center - size_v,
                .max = center + size_v,
            },
            color,
        );
    }
};
