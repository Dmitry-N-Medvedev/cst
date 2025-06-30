const std = @import("std");
const parseSingleLineSingleStringValue = @import("../parsers/parseSingleLineSingleStringValue.zig").parseSingleLineSingleStringValue;
const Token = @import("../Token.zig").Token;
const TokenError = @import("../Token.zig").TokenError;
const token = @tagName(Token.NDIMENS);

pub fn processTokenNDIMENS(line: []const u8) !u8 {
    const result = try parseSingleLineSingleStringValue(token, line);

    if (result.len == 0) {
        return TokenError.EmptyValue;
    }

    return try std.fmt.parseInt(u8, result, 10);
}

test "OK" {
    const expected_value: u8 = 3;
    const expected_value_char = std.fmt.digitToChar(expected_value, .upper);
    const line = @tagName(Token.NDIMENS) ++ " \t  " ++ &[_]u8{expected_value_char};
    const actualTokenReclValue = try processTokenNDIMENS(line);

    try std.testing.expectEqual(expected_value, actualTokenReclValue);
}

test "fail on empty value" {
    const line = @tagName(Token.NDIMENS);

    try std.testing.expectError(TokenError.EmptyValue, processTokenNDIMENS(line));
}

test "fail on KeyNotFound" {
    const line = "RANDOM_KEY \t 3";

    try std.testing.expectError(TokenError.KeyNotFound, processTokenNDIMENS(line));
}
