const std = @import("std");

const c = @import("c");

pub fn draw_enum_combo(comptime T: type, self: T) ?std.meta.Tag(T) {
    const tags = @typeInfo(std.meta.Tag(T)).@"enum".field_names;

    // Copy the slice to a null-terminated string for C API
    const my_name = tags[@backingInt(self)];

    var out: ?std.meta.Tag(T) = null;

    if (c.igBeginCombo("", @as([*c]const u8, @ptrCast(my_name[0..])), 0)) {
        var i: usize = 0;
        const TagIntType = @typeInfo(std.meta.Tag(T)).@"enum".tag_type;
        while (i < tags.len) : (i += 1) {
            const is_selected = i == @backingInt(self);

            const t = @as([*c]const u8, @ptrCast(tags[i]));
            if (c.rrIgSelectable(t, is_selected, 0, 0, 0)) {
                if (i != @backingInt(self)) {
                    out = @as(std.meta.Tag(T), @fromBackingInt(@intCast(@as(TagIntType, @intCast(i)))));
                }
            }
            if (is_selected) {
                c.igSetItemDefaultFocus();
            }
        }
        c.igEndCombo();
    }
    return out;
}
