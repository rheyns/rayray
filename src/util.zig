const std = @import("std");

// Returns the file contents, loaded from the file in debug builds and
// compiled in with release builds.  alloc must be an arena allocator, to
// prevent a memory leak in debug builds; this is enforced by the signature.
pub fn file_contents(arena: *std.heap.ArenaAllocator, comptime name: []const u8) ![]const u8 {
    const alloc: std.mem.Allocator = arena.allocator();
    switch (@import("builtin").mode) {
        .debug => {
            return std.Io.Dir.cwd().readFileAlloc(@import("runtime.zig").io, name, alloc, .unlimited);
        },
        .safe, .fast, .small => {
            const f = @embedFile("../" ++ name);
            return f[0..];
        },
    }
}
