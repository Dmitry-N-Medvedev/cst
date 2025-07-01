const std = @import("std");
const Token = @import("../Token.zig").Token;
const TokenError = @import("../Token.zig").TokenError;

pub inline fn parseSingleLineMultiValue(allocator: std.mem.Allocator, token: Token, line: []const u8) !std.ArrayList([]const u8) {
    if (!std.mem.startsWith(u8, line, @tagName(token))) {
        return TokenError.KeyNotFound;
    }

    var result = std.ArrayList([]const u8).init(allocator);
    errdefer result.deinit();

    var entries = std.mem.tokenizeAny(u8, line[@tagName(token).len..], &[_]u8{' '});
    while (entries.next()) |entry| {
        const item = std.mem.trim(u8, entry, &[_]u8{ '\t', ' ' });
        if (item.len == 0) {
            continue;
        }
        try result.append(item);
    }

    if (result.items.len == 0) {
        return TokenError.EmptyValue;
    }

    return result;
}

test "OK" {
    const allocator = std.testing.allocator;
    const TestCase = struct {
        token: Token,
        input: []const u8,
        expected: []const []const u8,
    };
    const test_cases = [_]TestCase{
        .{ .token = Token.DIMENS, .input = @tagName(Token.DIMENS) ++ "\t 8 44 6001", .expected = &[_][]const u8{ "8", "44", "6001" } },
    };

    for (test_cases) |test_case| {
        var result = try parseSingleLineMultiValue(allocator, test_case.token, test_case.input);
        defer result.deinit();

        try std.testing.expectEqual(result.items.len, test_case.expected.len);

        for (test_case.expected, 0..) |expected_item, i| {
            try std.testing.expectEqualStrings(expected_item, result.items[i]);
        }
    }
}

test "empty value" {
    const allocator = std.testing.allocator;

    try std.testing.expectError(TokenError.EmptyValue, parseSingleLineMultiValue(allocator, Token.DIMENS, @tagName(Token.DIMENS)));
}

test "fail TokenError.KeyNotFoundError" {
    const allocator = std.testing.allocator;

    try std.testing.expectError(TokenError.KeyNotFound, parseSingleLineMultiValue(allocator, Token.DIMENS, "ARBITRARY_KEY \t ARBITRARY_VALUE"));
}

// test "fail empty line" {
//     const allocator = std.testing.allocator;
//
//     try std.testing.expectError(TokenError.KeyNotFound, parseSingleLineMultiValue(allocator, @tagName(Token.DIMENS), ""));
// }
