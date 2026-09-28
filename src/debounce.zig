const std = @import("std");

const c = @import("c");

// The Debounce struct is triggered with update(dt).  After dt milliseconds,
// a call to check() returns true.  Intermediate calls to update() will restart
// the timer and change the value which will eventually be returned by check().
pub const Debounce = struct {
    const Self = @This();

    thread: ?std.Thread,

    // The mutex protects all of the variables below
    mutex: std.Io.Mutex,
    end_time_ms: i64,
    thread_running: bool,
    done: bool,

    pub fn init() Self {
        return Self{
            .mutex = .init,

            .end_time_ms = 0,
            .thread = null,
            .thread_running = false,
            .done = false,
        };
    }

    pub fn deinit(self: *Self) void {
        self.mutex.lockUncancelable(@import("runtime.zig").io);
        self.end_time_ms = 0;
        self.mutex.unlock(@import("runtime.zig").io);
        if (self.thread) |thread| thread.join();
    }

    fn run(self: *Self) void {
        while (true) {
            self.mutex.lockUncancelable(@import("runtime.zig").io);
            const now_time = @import("runtime.zig").milliseconds();
            if (now_time >= self.end_time_ms) {
                self.done = true;
                self.thread_running = false;
                self.mutex.unlock(@import("runtime.zig").io);
                break;
            } else {
                const dt = self.end_time_ms - now_time;
                self.mutex.unlock(@import("runtime.zig").io);
                std.Io.sleep(@import("runtime.zig").io, .fromMilliseconds(dt), .awake) catch unreachable;
            }
        }
        c.glfwPostEmptyEvent();
    }

    // After dt_ms milliseconds have elapsed, check() returns true.
    // Another update resets the timer.
    pub fn update(self: *Self, dt_ms: i64) !void {
        self.mutex.lockUncancelable(@import("runtime.zig").io);
        defer self.mutex.unlock(@import("runtime.zig").io);

        self.done = false;
        self.end_time_ms = @import("runtime.zig").milliseconds() + dt_ms;
        if (!self.thread_running) {
            if (self.thread) |thread| {
                thread.join();
            }
            self.thread = try std.Thread.spawn(.{}, Self.run, .{self});
            self.thread_running = true;
        } else {
            // The already-running thread will handle it
        }
    }

    pub fn check(self: *Self) bool {
        self.mutex.lockUncancelable(@import("runtime.zig").io);
        defer self.mutex.unlock(@import("runtime.zig").io);

        const out = self.done;
        self.done = false;
        return out;
    }
};
