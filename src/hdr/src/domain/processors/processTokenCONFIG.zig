const std = @import("std");
const parseSingleLineSingleValue = @import("../parsers/parseSingleLineSingleValue.zig").parseSingleLineSingleValue;
const Token = @import("../Token.zig").Token;
const TokenError = @import("../Token.zig").TokenError;

const TOKEN = Token.CONFIG;

pub fn processTokenCONFIG(line: []const u8) ![]const u8 {
    const result = try parseSingleLineSingleValue(TOKEN, line);

    if (result.len == 0) {
        return TokenError.EmptyValue;
    }

    return result;
}

test "OK" {
    const expected_value = "TRANSIENT";
    const line = @tagName(TOKEN) ++ " \t  '" ++ expected_value ++ "'";
    const actualTokenConfigValue = try processTokenCONFIG(line);

    try std.testing.expectEqualSlices(u8, expected_value, actualTokenConfigValue);
}

test "fail on empty value" {
    const line = @tagName(TOKEN);

    try std.testing.expectError(TokenError.EmptyValue, processTokenCONFIG(line));
}

test "fail on KeyNotFound" {
    const line = "RANDOM_KEY \t 'TRANSIENT'";

    try std.testing.expectError(TokenError.KeyNotFound, processTokenCONFIG(line));
}
