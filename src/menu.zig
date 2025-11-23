const d = @import("c.zig");
const c = d.c;
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
        if (c.IsCursorHidden()) c.EnableCursor();
        switch (state.menu.page) {
            .main => main(state),
            .settings => settings(state),
        }
    }

    fn main(state: *State) void {
        const w: f32 = @floatFromInt(c.GetRenderWidth());
        const h: f32 = @floatFromInt(c.GetRenderHeight());

        if (c.GuiButton(.{
            .width = 0.2 * w,
            .height = 0.05 * h,
            .x = 0.4 * w,
            .y = 0.4 * h,
        }, "Continue") == 1) {
            state.menu.enabled = false;
        }

        if (state.mode != .edit) c.GuiDisable();
        if (c.GuiButton(.{
            .width = 0.2 * w,
            .height = 0.05 * h,
            .x = 0.4 * w,
            .y = 0.46 * h,
        }, "Save") == 1) {
            state.editor.robot.save() catch {};
        }
        if (state.mode != .edit) c.GuiEnable();

        if (c.GuiButton(.{
            .width = 0.2 * w,
            .height = 0.05 * h,
            .x = 0.4 * w,
            .y = 0.52 * h,
        }, "Settings") == 1) {
            state.menu.page = .settings;
        }

        if (c.GuiButton(.{
            .width = 0.2 * w,
            .height = 0.05 * h,
            .x = 0.4 * w,
            .y = 0.58 * h,
        }, "Quit") == 1) {
            state.mode = .close;
            state.menu.enabled = false;
        }
    }

    fn settings(state: *State) void {
        const w: f32 = @floatFromInt(c.GetRenderWidth());
        const h: f32 = @floatFromInt(c.GetRenderHeight());

        _ = c.GuiPanel(.{
            .width = 0.2 * w,
            .height = 0.11 * h,
            .x = 0.4 * w,
            .y = 0.4 * h,
        }, "TODO");

        if (c.GuiButton(.{
            .width = 0.2 * w,
            .height = 0.05 * h,
            .x = 0.4 * w,
            .y = 0.52 * h,
        }, "Back") == 1) {
            state.menu.page = .main;
        }
    }
};
