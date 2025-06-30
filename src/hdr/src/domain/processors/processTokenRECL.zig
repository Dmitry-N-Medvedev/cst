const std = @import("std");
const parseSingleLineSingleValue = @import("../parsers/parseSingleLineSingleValue.zig").parseSingleLineSingleValue;
const Token = @import("../Token.zig").Token;
const TokenError = @import("../Token.zig").TokenError;
const token = @tagName(Token.RECL);

pub fn processTokenRECL(line: []const u8) !u8 {
    const result = try parseSingleLineSingleValue(token, line);

    if (result.len == 0) {
        return TokenError.EmptyValue;
    }

    return try std.fmt.parseInt(u8, result, 10);
}

test "OK" {
    const expected_value: u8 = 4;
    const expected_value_char = std.fmt.digitToChar(expected_value, .upper);
    const line = @tagName(Token.RECL) ++ " \t  " ++ &[_]u8{expected_value_char};
    const actualTokenReclValue = try processTokenRECL(line);

    try std.testing.expectEqual(expected_value, actualTokenReclValue);
}

test "fail on empty value" {
    const line = @tagName(Token.RECL);

    try std.testing.expectError(TokenError.EmptyValue, processTokenRECL(line));
}

test "fail on KeyNotFound" {
    const line = "RANDOM_KEY \t 4";

    try std.testing.expectError(TokenError.KeyNotFound, processTokenRECL(line));
}
