const std = @import("std");
const parseSingleLineSingleValue = @import("../parsers/parseSingleLineSingleValue.zig").parseSingleLineSingleValue;
const Token = @import("../Token.zig").Token;
const TokenError = @import("../Token.zig").TokenError;
const token = @tagName(Token.STEP);

pub fn processTokenSTEP(line: []const u8) !f64 {
    const result = try parseSingleLineSingleValue(token, line);

    if (result.len == 0) {
        return TokenError.EmptyValue;
    }

    return try std.fmt.parseFloat(f64, result);
}

test "OK" {
    const expected_value: f64 = 5.0000001E-02;
    var buff: [128]u8 = undefined;
    const line = try std.fmt.bufPrint(&buff, "{s} \t {}", .{ @tagName(Token.STEP), expected_value });
    const actualTokenReclValue = try processTokenSTEP(line);

    try std.testing.expectEqual(expected_value, actualTokenReclValue);
}

test "fail on empty value" {
    const line = @tagName(Token.STEP);

    try std.testing.expectError(TokenError.EmptyValue, processTokenSTEP(line));
}

test "fail on KeyNotFound" {
    const line = "RANDOM_KEY \t 5.0000001E-02";

    try std.testing.expectError(TokenError.KeyNotFound, processTokenSTEP(line));
}
