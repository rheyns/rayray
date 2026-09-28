const std = @import("std");

// Initialized before starting any workers; remains valid until they join.
pub var io: std.Io = undefined;

pub fn milliseconds() i64 {
    return std.Io.Clock.awake.now(io).toMilliseconds();
}
