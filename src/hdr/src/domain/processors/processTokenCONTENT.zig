const std = @import("std");
const parseSingleLineSingleValue = @import("../parsers/parseSingleLineSingleValue.zig").parseSingleLineSingleValue;
const Token = @import("../Token.zig").Token;
const TokenError = @import("../Token.zig").TokenError;

const TOKEN = Token.CONTENT;

pub fn processTokenCONTENT(line: []const u8) ![]const u8 {
    const result = try parseSingleLineSingleValue(TOKEN, line);

    if (result.len == 0) {
        return TokenError.EmptyValue;
    }

    return result;
}

test "OK" {
    const expected_value = "START";
    const line = @tagName(TOKEN) ++ " \t  '" ++ expected_value ++ "'";
    const actualTokenContentValue = try processTokenCONTENT(line);

    try std.testing.expectEqualSlices(u8, expected_value, actualTokenContentValue);
}

test "fail on empty value" {
    const line = @tagName(TOKEN);

    try std.testing.expectError(TokenError.EmptyValue, processTokenCONTENT(line));
}

test "fail on KeyNotFound" {
    const line = "RANDOM_KEY \t START";

    try std.testing.expectError(TokenError.KeyNotFound, processTokenCONTENT(line));
}
