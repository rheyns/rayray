const std = @import("std");

const c = @import("c");
const Window = @import("window.zig").Window;
const Options = @import("options.zig").Options;

pub fn main(init: std.process.Init) anyerror!void {
    @import("runtime.zig").io = init.io;
    var gp_alloc = std.heap.DebugAllocator(.{}){};
    defer std.debug.assert(gp_alloc.deinit() == .ok);
    const alloc: std.mem.Allocator = gp_alloc.allocator();

    if (c.glfwInit() != c.GLFW_TRUE) {
        std.debug.panic("Could not initialize glfw", .{});
    }

    defer c.glfwTerminate();

    const options = try Options.parse_args(try init.minimal.args.toSlice(init.arena.allocator()));

    var window = try Window.init(alloc, options, "rayray");
    defer window.deinit();

    try window.run();
}
