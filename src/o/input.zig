const c = @import("c.zig").c;

pub const Analog = union(enum) {
    mouse: Mouse,

    pub fn value(an: Analog) @Vector(2, f32) {
        return switch (an) {
            .mouse => |m| m.value(),
        };
    }

    pub const Mouse = enum {
        pub fn value(mouse: Mouse) @Vector(2, f32) {
            const vec = switch (mouse) {
                .wheel => c.GetMouseWheelMoveV(),
                .move => c.GetMouseDelta(),
            };
            return .{ vec.x, vec.y };
        }

        wheel,
        move,
    };
};

pub const Digital = union(enum) {
    key: Key,
    mouse: Mouse,

    pub fn pressed(di: Digital) bool {
        return switch (di) {
            .key => |k| k.pressed(),
            .mouse => |m| m.pressed(),
        };
    }

    pub fn isDown(di: Digital) bool {
        return switch (di) {
            .key => |k| k.isDown(),
            .mouse => |m| m.isDown(),
        };
    }

    pub fn released(di: Digital) bool {
        return switch (di) {
            .key => |k| k.released(),
            .mouse => |m| m.released(),
        };
    }

    pub const Mouse = enum(c_int) {
        pub fn pressed(mouse: Mouse) bool {
            return c.IsMouseButtonPressed(@intFromEnum(mouse));
        }

        pub fn isDown(mouse: Mouse) bool {
            return c.IsMouseButtonDown(@intFromEnum(mouse));
        }

        pub fn released(mouse: Mouse) bool {
            return c.IsMouseButtonReleased(@intFromEnum(mouse));
        }

        back = c.MOUSE_BUTTON_BACK,
        extra = c.MOUSE_BUTTON_EXTRA,
        forward = c.MOUSE_BUTTON_FORWARD,
        left = c.MOUSE_BUTTON_LEFT,
        middle = c.MOUSE_BUTTON_MIDDLE,
        right = c.MOUSE_BUTTON_RIGHT,
        side = c.MOUSE_BUTTON_SIDE,
    };

    pub const Key = enum(c_int) {
        pub fn pressed(key: Key) bool {
            return c.IsKeyPressed(@intFromEnum(key));
        }

        pub fn isDown(key: Key) bool {
            return c.IsKeyDown(@intFromEnum(key));
        }

        pub fn released(key: Key) bool {
            return c.IsKeyReleased(@intFromEnum(key));
        }

        dead = c.KEY_NULL,
        apostrophe = c.KEY_APOSTROPHE,
        comma = c.KEY_COMMA,
        minus = c.KEY_MINUS,
        period = c.KEY_PERIOD,
        slash = c.KEY_SLASH,
        zero = c.KEY_ZERO,
        one = c.KEY_ONE,
        two = c.KEY_TWO,
        three = c.KEY_THREE,
        four = c.KEY_FOUR,
        five = c.KEY_FIVE,
        six = c.KEY_SIX,
        seven = c.KEY_SEVEN,
        eight = c.KEY_EIGHT,
        nine = c.KEY_NINE,
        semicolon = c.KEY_SEMICOLON,
        equal = c.KEY_EQUAL,
        a = c.KEY_A,
        b = c.KEY_B,
        c = c.KEY_C,
        d = c.KEY_D,
        e = c.KEY_E,
        f = c.KEY_F,
        g = c.KEY_G,
        h = c.KEY_H,
        i = c.KEY_I,
        j = c.KEY_J,
        k = c.KEY_K,
        l = c.KEY_L,
        m = c.KEY_M,
        n = c.KEY_N,
        o = c.KEY_O,
        p = c.KEY_P,
        q = c.KEY_Q,
        r = c.KEY_R,
        s = c.KEY_S,
        t = c.KEY_T,
        u = c.KEY_U,
        v = c.KEY_V,
        w = c.KEY_W,
        x = c.KEY_X,
        y = c.KEY_Y,
        z = c.KEY_Z,
        left_bracket = c.KEY_LEFT_BRACKET,
        backslash = c.KEY_BACKSLASH,
        right_bracket = c.KEY_RIGHT_BRACKET,
        grave = c.KEY_GRAVE,
        space = c.KEY_SPACE,
        escape = c.KEY_ESCAPE,
        enter = c.KEY_ENTER,
        tab = c.KEY_TAB,
        backspace = c.KEY_BACKSPACE,
        insert = c.KEY_INSERT,
        delete = c.KEY_DELETE,
        right = c.KEY_RIGHT,
        left = c.KEY_LEFT,
        down = c.KEY_DOWN,
        up = c.KEY_UP,
        page_up = c.KEY_PAGE_UP,
        page_down = c.KEY_PAGE_DOWN,
        home = c.KEY_HOME,
        key_end = c.KEY_END,
        caps_lock = c.KEY_CAPS_LOCK,
        scroll_lock = c.KEY_SCROLL_LOCK,
        num_lock = c.KEY_NUM_LOCK,
        print_screen = c.KEY_PRINT_SCREEN,
        pause = c.KEY_PAUSE,
        f1 = c.KEY_F1,
        f2 = c.KEY_F2,
        f3 = c.KEY_F3,
        f4 = c.KEY_F4,
        f5 = c.KEY_F5,
        f6 = c.KEY_F6,
        f7 = c.KEY_F7,
        f8 = c.KEY_F8,
        f9 = c.KEY_F9,
        f10 = c.KEY_F10,
        f11 = c.KEY_F11,
        f12 = c.KEY_F12,
        left_shift = c.KEY_LEFT_SHIFT,
        left_control = c.KEY_LEFT_CONTROL,
        left_alt = c.KEY_LEFT_ALT,
        left_super = c.KEY_LEFT_SUPER,
        right_shift = c.KEY_RIGHT_SHIFT,
        right_control = c.KEY_RIGHT_CONTROL,
        right_alt = c.KEY_RIGHT_ALT,
        right_super = c.KEY_RIGHT_SUPER,
        kb_menu = c.KEY_KB_MENU,
        keypad_0 = c.KEY_KP_0,
        keypad_1 = c.KEY_KP_1,
        keypad_2 = c.KEY_KP_2,
        keypad_3 = c.KEY_KP_3,
        keypad_4 = c.KEY_KP_4,
        keypad_5 = c.KEY_KP_5,
        keypad_6 = c.KEY_KP_6,
        keypad_7 = c.KEY_KP_7,
        keypad_8 = c.KEY_KP_8,
        keypad_9 = c.KEY_KP_9,
        keypad_decimal = c.KEY_KP_DECIMAL,
        keypad_divide = c.KEY_KP_DIVIDE,
        keypad_multiply = c.KEY_KP_MULTIPLY,
        keypad_substract = c.KEY_KP_SUBTRACT,
        keypad_add = c.KEY_KP_ADD,
        keypad_enter = c.KEY_KP_ENTER,
        keypad_equal = c.KEY_KP_EQUAL,
        back = c.KEY_BACK,
        menu = c.KEY_MENU,
        volumne_up = c.KEY_VOLUME_UP,
        volumne_down = c.KEY_VOLUME_DOWN,
    };
};
