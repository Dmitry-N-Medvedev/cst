const std = @import("std");
const Token = @import("../Token.zig").Token;
const TokenError = @import("../Token.zig").TokenError;

pub inline fn parseSingleLineSingleStringValue(key: []const u8, line: []const u8) ![]const u8 {
    if (!std.mem.startsWith(u8, line, key)) {
        return TokenError.KeyNotFound;
    }

    return std.mem.trim(u8, line[key.len..], &[_]u8{ ' ', '\t', '\'' });
}

test "OK" {
    const KeyValue = struct {
        key: Token,
        value: []const u8,
        expected_value: []const u8,
    };
    const KeyValues = [_]KeyValue{
        KeyValue{ .key = Token.FILE, .value = @tagName(Token.FILE) ++ " \t startup.$41\r\nYOU HAVE ERROR IN YOUR CODE\r\n", .expected_value = "startup.$41" },
        KeyValue{ .key = Token.ACCESS, .value = @tagName(Token.ACCESS) ++ " \t D\r\nYOU HAVE ERROR IN YOUR CODE\r\n", .expected_value = "D" },
        KeyValue{ .key = Token.FORM, .value = @tagName(Token.FORM) ++ " \t F\r\nYOU HAVE ERROR IN YOUR CODE\r\n", .expected_value = "F" },
        KeyValue{ .key = Token.RECL, .value = @tagName(Token.RECL) ++ " \t 4\r\nYOU HAVE ERROR IN YOUR CODE\r\n", .expected_value = "4" },
        KeyValue{ .key = Token.FORMAT, .value = @tagName(Token.FORMAT) ++ " \t R*4\r\nYOU HAVE ERROR IN YOUR CODE\r\n", .expected_value = "R*4" },
        KeyValue{ .key = Token.CONTENT, .value = @tagName(Token.CONTENT) ++ " \t 'START'\r\nYOU HAVE ERROR IN YOUR CODE\r\n", .expected_value = "START" },
        KeyValue{ .key = Token.CONFIG, .value = @tagName(Token.CONFIG) ++ " \t 'TRANSIENT'\r\nYOU HAVE ERROR IN YOUR CODE\r\n", .expected_value = "TRANSIENT" },
        KeyValue{ .key = Token.NDIMENS, .value = @tagName(Token.NDIMENS) ++ " \t 3\r\nYOU HAVE ERROR IN YOUR CODE\r\n", .expected_value = "3" },
        KeyValue{ .key = Token.GENLAB, .value = @tagName(Token.GENLAB) ++ " \t 'Blade 1 Loads: Root axes'\r\nYOU HAVE ERROR IN YOUR CODE\r\n", .expected_value = "Blade 1 Loads: Root axes" },
        KeyValue{ .key = Token.AXISLAB, .value = @tagName(Token.AXISLAB) ++ " \t 'Distance along blade'\r\nYOU HAVE ERROR IN YOUR CODE\r\n", .expected_value = "Distance along blade" },
        KeyValue{ .key = Token.AXIUNIT, .value = @tagName(Token.AXIUNIT) ++ " \t L\r\nYOU HAVE ERROR IN YOUR CODE\r\n", .expected_value = "L" },
        KeyValue{ .key = Token.AXIMETH, .value = @tagName(Token.AXIMETH) ++ " \t 3\r\nYOU HAVE ERROR IN YOUR CODE\r\n", .expected_value = "3" },
        KeyValue{ .key = Token.MIN, .value = @tagName(Token.MIN) ++ " \t 0.0000000E+00\r\nYOU HAVE ERROR IN YOUR CODE\r\n", .expected_value = "0.0000000E+00" },
        KeyValue{ .key = Token.STEP, .value = @tagName(Token.STEP) ++ " \t 5.0000001E-02\r\nYOU HAVE ERROR IN YOUR CODE\r\n", .expected_value = "5.0000001E-02" },
        KeyValue{ .key = Token.NVARS, .value = @tagName(Token.NVARS) ++ " \t 0\r\nYOU HAVE ERROR IN YOUR CODE\r\n", .expected_value = "0" },
    };

    for (KeyValues) |kv| {
        var lines = std.mem.tokenizeAny(u8, kv.value, "\r\n");

        var resolved_value: []const u8 = undefined;
        while (lines.next()) |line| {
            resolved_value = try parseSingleLineSingleStringValue(@tagName(kv.key), line);

            break;
        }
        try std.testing.expectEqualSlices(u8, kv.expected_value, resolved_value);
    }
}

test "empty value" {
    const resolved_value = try parseSingleLineSingleStringValue(@tagName(Token.FILE), @tagName(Token.FILE));

    try std.testing.expectEqualStrings("", resolved_value);
}

test "fail TokenError.KeyNotFoundError" {
    const line = "UNKNOWN_TOKEN\t 'unknown value'";

    try std.testing.expectError(TokenError.KeyNotFound, parseSingleLineSingleStringValue(@tagName(Token.FILE), line));
}
