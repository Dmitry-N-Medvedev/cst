const std = @import("std");
const parseSingleLineSingleValueString = @import("../parsers/parseSingleLineSingleValueString.zig").parseSingleLineSingleValueString;
const Token = @import("../Token.zig").Token;
const TokenError = @import("../Token.zig").TokenError;
const token = @tagName(Token.CONFIG);

pub fn processTokenCONFIG(line: []const u8) ![]const u8 {
    const result = try parseSingleLineSingleValueString(token, line);

    if (result.len == 0) {
        return TokenError.EmptyValue;
    }

    return result;
}

test "OK" {
    const expected_value = "TRANSIENT";
    const line = @tagName(Token.CONFIG) ++ " \t  '" ++ expected_value ++ "'";
    const actualTokenConfigValue = try processTokenCONFIG(line);

    try std.testing.expectEqualSlices(u8, expected_value, actualTokenConfigValue);
}

test "fail on empty value" {
    const line = @tagName(Token.CONFIG);

    try std.testing.expectError(TokenError.EmptyValue, processTokenCONFIG(line));
}

test "fail on KeyNotFound" {
    const line = "RANDOM_KEY \t 'TRANSIENT'";

    try std.testing.expectError(TokenError.KeyNotFound, processTokenCONFIG(line));
}
