const std = @import("std");
const parseSingleLineSingleValueString = @import("../parsers/parseSingleLineSingleValueString.zig").parseSingleLineSingleValueString;
const Token = @import("../Token.zig").Token;
const TokenError = @import("../Token.zig").TokenError;
const token = @tagName(Token.FORMAT);

pub fn processTokenFORMAT(line: []const u8) ![]const u8 {
    const result = try parseSingleLineSingleValueString(token, line);

    if (result.len == 0) {
        return TokenError.EmptyValue;
    }

    return result;
}

test "OK" {
    const expected_value = "R*4";
    const line = @tagName(Token.FORMAT) ++ " \t  " ++ expected_value;
    const actualTokenFormatValue = try processTokenFORMAT(line);

    try std.testing.expectEqualSlices(u8, expected_value, actualTokenFormatValue);
}

test "fail on empty value" {
    const line = @tagName(Token.FORMAT);

    try std.testing.expectError(TokenError.EmptyValue, processTokenFORMAT(line));
}

test "fail on KeyNotFound" {
    const line = "RANDOM_KEY \t R*4";

    try std.testing.expectError(TokenError.KeyNotFound, processTokenFORMAT(line));
}
