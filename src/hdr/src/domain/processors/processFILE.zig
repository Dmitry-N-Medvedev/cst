const std = @import("std");
const Token = @import("../Token.zig").Token;
const TokenError = @import("errors/TokenError.zig").TokenError;
const BufferError = @import("errors/BufferError.zig").BufferError;
const ProcessFn = @import("ProcessFn.zig").ProcessFn;

pub fn processFILE(allocator: std.mem.Allocator, buffer: []const u8, buffer_index: *usize) ![]const u8 {
    if (buffer_index.* >= buffer.len) {
        return BufferError.TooSmall;
    }

    const tag = @tagName(Token.FILE);

    if (!std.mem.startsWith(u8, buffer[buffer_index.*..], tag)) {
        return TokenError.NotFound;
    }

    var idx = buffer_index.*;

    idx += tag.len;

    const cr_index = tag.len + (std.mem.indexOfScalar(u8, buffer[idx..], '\r') orelse idx);
    const string_len = cr_index - idx;
    const result = try allocator.alloc(u8, string_len);
    defer allocator.free(result);
    const slice = buffer[idx..(idx + string_len)];
    std.mem.copyForwards(u8, result, slice);
    const trimmed = allocator.dupe(u8, std.mem.trimLeft(u8, result, &[_]u8{ '\t', ' ' }));

    buffer_index.* = idx + string_len;

    return trimmed;
}

test "OK: processFILE" {
    const allocator = std.testing.allocator;
    const expected_value = "startup.$41";
    const buffer = try std.fmt.allocPrint(allocator, "FILE\t {s}\r\nsome other text\r\n", .{
        expected_value,
    });
    defer allocator.free(buffer);
    var buffer_index: usize = 0;

    const result = try processFILE(allocator, buffer, &buffer_index);
    defer allocator.free(result);

    try std.testing.expectEqualSlices(u8, expected_value, result);
}

// test "ER: processFILE: BufferError.TooSmall" {
//     const allocator = std.testing.allocator;
//     const buffer = "\r\n";
//     // const expected_value = "startup.$41";
//     var buffer_index: usize = 0;
//
//     try std.testing.expect(buffer_index <= buffer.len);
//
//     // const result = try processFILE(allocator, buffer, &buffer_index);
//     // defer allocator.free(result);
//
//     // try std.testing.expect(std.mem.eql(u8, buffer, expected_value));
//     try std.testing.expectError(BufferError.TooSmall, processFILE(allocator, buffer, &buffer_index));
// }
