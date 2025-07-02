const std = @import("std");
const parseSingleLineSingleValue = @import("../parsers/parseSingleLineSingleValue.zig").parseSingleLineSingleValue;
const Token = @import("../Token.zig").Token;
const TokenError = @import("../Token.zig").TokenError;

const TOKEN = Token.NDIMENS;

pub fn processTokenNDIMENS(line: []const u8) !u8 {
    const result = try parseSingleLineSingleValue(TOKEN, line);

    if (result.len == 0) {
        return TokenError.EmptyValue;
    }

    return try std.fmt.parseInt(u8, result, 10);
}

test "OK" {
    const expected_value: u8 = 3;
    const expected_value_char = std.fmt.digitToChar(expected_value, .upper);
    const line = @tagName(TOKEN) ++ " \t  " ++ &[_]u8{expected_value_char};
    const actualTokenReclValue = try processTokenNDIMENS(line);

    try std.testing.expectEqual(expected_value, actualTokenReclValue);
}

test "fail on empty value" {
    const line = @tagName(TOKEN);

    try std.testing.expectError(TokenError.EmptyValue, processTokenNDIMENS(line));
}

test "fail on KeyNotFound" {
    const line = "RANDOM_KEY \t 3";

    try std.testing.expectError(TokenError.KeyNotFound, processTokenNDIMENS(line));
}
