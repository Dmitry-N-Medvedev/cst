const std = @import("std");
const parseSingleLineSingleValue = @import("../parsers/parseSingleLineSingleValue.zig").parseSingleLineSingleValue;
const Token = @import("../Token.zig").Token;
const TokenError = @import("../Token.zig").TokenError;
const token = @tagName(Token.GENLAB);

pub fn processTokenGENLAB(line: []const u8) ![]const u8 {
    const result = try parseSingleLineSingleValue(token, line);

    if (result.len == 0) {
        return TokenError.EmptyValue;
    }

    return result;
}

test "OK" {
    const expected_value = "Blade 1 Loads: Root axes";
    const line = @tagName(Token.GENLAB) ++ " \t  '" ++ expected_value ++ "'";
    const actualTokenConfigValue = try processTokenGENLAB(line);

    try std.testing.expectEqualSlices(u8, expected_value, actualTokenConfigValue);
}

test "fail on empty value" {
    const line = @tagName(Token.GENLAB);

    try std.testing.expectError(TokenError.EmptyValue, processTokenGENLAB(line));
}

test "fail on KeyNotFound" {
    const line = "RANDOM_KEY \t 'something irrelevant'";

    try std.testing.expectError(TokenError.KeyNotFound, processTokenGENLAB(line));
}
