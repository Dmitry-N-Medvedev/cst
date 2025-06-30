const std = @import("std");
const parseSingleLineSingleStringValue = @import("../parsers/parseSingleLineSingleStringValue.zig").parseSingleLineSingleStringValue;
const Token = @import("../Token.zig").Token;
const TokenError = @import("../Token.zig").TokenError;
const token = @tagName(Token.AXISLAB);

pub fn processTokenAXISLAB(line: []const u8) ![]const u8 {
    const result = try parseSingleLineSingleStringValue(token, line);

    if (result.len == 0) {
        return TokenError.EmptyValue;
    }

    return result;
}

test "OK" {
    const expected_value = "Distance along blade";
    const line = @tagName(Token.AXISLAB) ++ " \t  '" ++ expected_value ++ "'";
    const actualTokenConfigValue = try processTokenAXISLAB(line);

    try std.testing.expectEqualSlices(u8, expected_value, actualTokenConfigValue);
}

test "fail on empty value" {
    const line = @tagName(Token.AXISLAB);

    try std.testing.expectError(TokenError.EmptyValue, processTokenAXISLAB(line));
}

test "fail on KeyNotFound" {
    const line = "RANDOM_KEY \t 'something irrelevant'";

    try std.testing.expectError(TokenError.KeyNotFound, processTokenAXISLAB(line));
}
