const o = @import("o.zig");
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
        if (o.cursor.hidden()) o.cursor.enable();
        switch (state.menu.page) {
            .main => main(state),
            .settings => settings(state),
        }
    }

    fn main(state: *State) void {
        const sz = o.draw.size();
        const S = @TypeOf(sz);

        if (o.gui.button(.{
            .min = sz * S{ 0.4, 0.4 },
            .max = sz * S{ 0.6, 0.45 },
        }, "Continue")) {
            state.menu.enabled = false;
        }

        if (state.mode != .edit) o.gui.disable();
        if (o.gui.button(.{
            .min = sz * S{ 0.4, 0.46 },
            .max = sz * S{ 0.6, 0.51 },
        }, "Save")) {
            state.editor.robot.save() catch {};
        }
        if (state.mode != .edit) o.gui.enable();

        if (o.gui.button(.{
            .min = sz * S{ 0.4, 0.52 },
            .max = sz * S{ 0.6, 0.57 },
        }, "Settings")) {
            state.menu.page = .settings;
        }

        if (o.gui.button(.{
            .min = sz * S{ 0.4, 0.58 },
            .max = sz * S{ 0.6, 0.63 },
        }, "Quit")) {
            state.mode = .close;
            state.menu.enabled = false;
        }
    }

    fn settings(state: *State) void {
        const sz = o.draw.size();
        const S = @TypeOf(sz);

        o.gui.panel(.{
            .min = sz * S{ 0.4, 0.4 },
            .max = sz * S{ 0.6, 0.51 },
        }, "TODO");

        if (o.gui.button(.{
            .min = sz * S{ 0.4, 0.52 },
            .max = sz * S{ 0.6, 0.57 },
        }, "Back")) {
            state.menu.page = .main;
        }
    }
};
