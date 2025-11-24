const d = @import("c.zig");
const State = @import("state.zig").State;
const Options = State.Options;

const Page = enum {
    main,
    settings,
};

pub const Menu = struct {
    enabled: bool = false,
    page: Page = .main,

    pub fn show(state: *State) void {
        if (!state.menu.enabled) return;
        if (d.Cursor.hidden()) d.Cursor.enable();
        switch (state.menu.page) {
            .main => main(state),
            .settings => settings(state),
        }
    }

    fn main(state: *State) void {
        const w: f32 = @floatFromInt(d.Window.width());
        const h: f32 = @floatFromInt(d.Window.height());

        if (d.Gui.button(.{
            .width = 0.2 * w,
            .height = 0.05 * h,
            .x = 0.4 * w,
            .y = 0.4 * h,
        }, "Continue")) {
            state.menu.enabled = false;
        }

        if (state.mode != .edit) d.Gui.disable();
        if (d.Gui.button(.{
            .width = 0.2 * w,
            .height = 0.05 * h,
            .x = 0.4 * w,
            .y = 0.46 * h,
        }, "Save")) {
            state.editor.robot.save() catch {};
        }
        if (state.mode != .edit) d.Gui.enable();

        if (d.Gui.button(.{
            .width = 0.2 * w,
            .height = 0.05 * h,
            .x = 0.4 * w,
            .y = 0.52 * h,
        }, "Settings")) {
            state.menu.page = .settings;
        }

        if (d.Gui.button(.{
            .width = 0.2 * w,
            .height = 0.05 * h,
            .x = 0.4 * w,
            .y = 0.58 * h,
        }, "Quit")) {
            state.mode = .close;
            state.menu.enabled = false;
        }
    }

    fn settings(state: *State) void {
        const w: f32 = @floatFromInt(d.Window.width());
        const h: f32 = @floatFromInt(d.Window.height());

        d.Gui.panel(.{
            .width = 0.2 * w,
            .height = 0.11 * h,
            .x = 0.4 * w,
            .y = 0.4 * h,
        }, "TODO");

        if (d.Gui.button(.{
            .width = 0.2 * w,
            .height = 0.05 * h,
            .x = 0.4 * w,
            .y = 0.52 * h,
        }, "Back")) {
            state.menu.page = .main;
        }
    }
};
