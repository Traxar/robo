const c = @import("c.zig");
const Options = @import("options.zig").Options;
const Mode = @import("mode.zig").Mode;

const Page = enum {
    main,
    settings,
};

pub const Menu = struct {
    enabled: bool = false,
    page: Page = .main,

    pub fn show(menu: *Menu, options: *Options, mode: *Mode) void {
        if (!menu.enabled) return;
        if (c.IsCursorHidden()) c.EnableCursor();
        switch (menu.page) {
            .main => menu.main(options, mode),
            .settings => menu.settings(options, mode),
        }
    }

    fn main(menu: *Menu, options: *Options, mode: *Mode) void {
        _ = options;
        const w: f32 = @floatFromInt(c.GetRenderWidth());
        const h: f32 = @floatFromInt(c.GetRenderHeight());

        if (c.GuiButton(.{
            .width = 0.2 * w,
            .height = 0.05 * h,
            .x = 0.4 * w,
            .y = 0.4 * h,
        }, "Continue") == 1) {
            menu.enabled = false;
        }

        if (c.GuiButton(.{
            .width = 0.2 * w,
            .height = 0.05 * h,
            .x = 0.4 * w,
            .y = 0.46 * h,
        }, "Settings") == 1) {
            menu.page = .settings;
        }

        if (c.GuiButton(.{
            .width = 0.2 * w,
            .height = 0.05 * h,
            .x = 0.4 * w,
            .y = 0.52 * h,
        }, "Quit") == 1) {
            mode.* = .close;
            menu.enabled = false;
        }
    }

    fn settings(menu: *Menu, options: *Options, mode: *Mode) void {
        _ = options;
        _ = mode;
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
            menu.page = .main;
        }
    }
};
