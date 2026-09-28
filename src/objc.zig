const std = @import("std");
const c = @import("c.zig");

fn symbol(name: [*:0]const u8) *c_void {
    // Darwin RTLD_DEFAULT is (void *)-2; Zig 0.8 cannot translate this C macro.
    // GLFW loads the Objective C runtime, avoiding the old linker's SDK stub issues.
    const default_handle = @intToPtr(?*c_void, std.math.maxInt(usize) - 1);
    return c.dlsym(default_handle, name) orelse
        std.debug.panic("Could not find Objective C runtime symbol", .{});
}

pub fn class(s: [*c]const u8) c.id {
    const lookup = @ptrCast(
        fn ([*c]const u8) callconv(.C) c.Class,
        @alignCast(4, symbol("objc_lookUpClass")),
    );
    return @ptrCast(c.id, @alignCast(8, lookup(s)));
}

pub fn call(obj: c.id, sel_name: [*c]const u8) c.id {
    const get_uid = @ptrCast(
        fn ([*c]const u8) callconv(.C) c.SEL,
        @alignCast(4, symbol("sel_getUid")),
    );
    const f = @ptrCast(
        fn (c.id, c.SEL) callconv(.C) c.id,
        @alignCast(4, symbol("objc_msgSend")),
    );
    return f(obj, get_uid(sel_name));
}

pub fn call_(obj: c.id, sel_name: [*c]const u8, arg: anytype) c.id {
    //  objc_msgSend has the prototype "void objc_msgSend(void)",
    //  so we have to cast it based on the types of our arguments
    //  (https://www.mikeash.com/pyblog/objc_msgsends-new-prototype.html)
    const get_uid = @ptrCast(
        fn ([*c]const u8) callconv(.C) c.SEL,
        @alignCast(4, symbol("sel_getUid")),
    );
    const f = @ptrCast(
        fn (c.id, c.SEL, @TypeOf(arg)) callconv(.C) c.id,
        @alignCast(4, symbol("objc_msgSend")),
    );
    return f(obj, get_uid(sel_name), arg);
}
