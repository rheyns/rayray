const std = @import("std");
// C-compatible allocators, so we can use the Zig GPA's leak-checking
// in Dear ImGui and other C libraries.

// We'll pad every allocation with a header to recover its length
const ALLOC_OFFSET: usize = @sizeOf(std.c.max_align_t);

pub export fn alloc_func(sz: usize, user_data: ?*anyopaque) *anyopaque {
    const alloc = @as(*std.mem.Allocator, @ptrCast(@alignCast(user_data)));
    const full_size = sz + ALLOC_OFFSET;
    const out = alloc.alignedAlloc(u8, .of(std.c.max_align_t), full_size) catch |err| {
        std.debug.panic("Could not allocate: {}\n", .{err});
    };
    std.mem.copyForwards(u8, out[0..@sizeOf(usize)], std.mem.asBytes(&full_size));
    return &out[ALLOC_OFFSET];
}

pub export fn free_func(ptr: ?*anyopaque, user_data: ?*anyopaque) void {
    if (ptr == null) {
        return;
    }
    const alloc = @as(*std.mem.Allocator, @ptrCast(@alignCast(user_data)));
    var size: usize = undefined;
    const ptr_u8 = @as([*]align(@alignOf(std.c.max_align_t)) u8, @ptrCast(@alignCast(ptr))) - ALLOC_OFFSET;
    std.mem.copyForwards(u8, std.mem.asBytes(&size), ptr_u8[0..@sizeOf(usize)]);
    alloc.free(ptr_u8[0..size]);
}
