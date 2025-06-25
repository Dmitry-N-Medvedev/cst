const std = @import("std");
const TokenError = @import("errors/TokenError.zig").TokenError;

pub const ProcessFn: type = *const fn (allocator: std.mem.Allocator, buffer: []const u8, buffer_index: *usize) TokenError![]const u8;
