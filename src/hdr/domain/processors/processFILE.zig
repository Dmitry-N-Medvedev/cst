const std = @import("std");
const Token = @import("../Token.zig").Token;
const TokenError = @import("errors/TokenError.zig").TokenError;
const ProcessFn = @import("ProcessFn.zig").ProcessFn;

pub fn processFILE(allocator: std.mem.Allocator, buffer: []const u8, buffer_index: *usize) ![]const u8 {
    if (buffer_index.* >= buffer.len) {
        return TokenError.NotFound;
    }

    if (!std.mem.startsWith(u8, buffer[buffer_index.*..], @tagName(Token.FILE))) {
        return TokenError.NotFound;
    }

    const cr_index = std.mem.indexOf(u8, buffer[buffer_index.*..], '\r') orelse unreachable;
    const string_len = cr_index - buffer_index.*;
    var result = try allocator.alloc(u8, string_len);
    const slice = buffer[buffer_index.*..];
    std.mem.copyForwards(u8, result[0..string_len], slice);

    return result;
}

test "processFILE" {
    const allocator = std.testing.allocator;
    const expected_value = "startup.$41";
    const buffer = "FILE\t " ++ expected_value ++ "\r\n";
    var buffer_index: usize = 0;

    const result = try processFILE(allocator, buffer, &buffer_index);
    defer allocator.free(result);

    try std.testing.expect(std.mem.eql(u8, result, expected_value));
}
