const std = @import("std");
const parseSingleLineSingleValue = @import("../parsers/parseSingleLineSingleValue.zig").parseSingleLineSingleValue;
const Token = @import("../Token.zig").Token;
const TokenError = @import("../Token.zig").TokenError;

const TOKEN = Token.MIN;

pub fn processTokenMIN(line: []const u8) !f64 {
    const result = try parseSingleLineSingleValue(TOKEN, line);

    if (result.len == 0) {
        return TokenError.EmptyValue;
    }

    return try std.fmt.parseFloat(f64, result);
}

test "OK" {
    const expected_value: f64 = 0.0000000E+00;
    var buff: [128]u8 = undefined;
    const line = try std.fmt.bufPrint(&buff, "{s} \t {}", .{ @tagName(TOKEN), expected_value });
    const actualTokenReclValue = try processTokenMIN(line);

    try std.testing.expectEqual(expected_value, actualTokenReclValue);
}

test "fail on empty value" {
    const line = @tagName(TOKEN);

    try std.testing.expectError(TokenError.EmptyValue, processTokenMIN(line));
}

test "fail on KeyNotFound" {
    const line = "RANDOM_KEY \t 0.0000000E+00";

    try std.testing.expectError(TokenError.KeyNotFound, processTokenMIN(line));
}
