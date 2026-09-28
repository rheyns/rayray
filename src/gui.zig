const std = @import("std");

const c = @import("c");
const Backend = @import("gui/backend.zig").Backend;

pub const Gui = struct {
    const Self = @This();

    ctx: *c.ImGuiContext,
    allocator_context: *std.mem.Allocator,
    backend: Backend,

    pub fn init(alloc: std.mem.Allocator, window: *c.GLFWwindow, device: c.WGPUDeviceId) !Self {
        const context = try alloc.create(std.mem.Allocator);
        context.* = alloc;
        errdefer alloc.destroy(context);
        c.igSetAllocatorFunctions(
            @import("c.zig").alloc_func,
            @import("c.zig").free_func,
            context,
        );
        const ctx = c.igCreateContext(null);
        c.igSetCurrentContext(ctx);
        errdefer c.igDestroyContext(ctx);

        return Self{
            .ctx = ctx,
            .allocator_context = context,
            .backend = try Backend.init(alloc, window, device),
        };
    }

    pub fn deinit(self: *Self) void {
        c.ImGui_ImplGlfw_Shutdown();
        c.igDestroyContext(self.ctx);
        self.backend.deinit();
        self.allocator_context.destroy(self.allocator_context);
    }

    pub fn new_frame(self: *Self) void {
        c.ImGui_ImplGlfw_NewFrame();
        self.backend.new_frame();
        c.igNewFrame();
    }

    pub fn draw(
        self: *Self,
        next_texture: c.WGPUOption_TextureViewId,
        cmd_encoder: c.WGPUCommandEncoderId,
    ) void {
        c.igRender();
        const draw_data = c.igGetDrawData();
        self.backend.render_draw_data(next_texture, cmd_encoder, draw_data);
    }
};
