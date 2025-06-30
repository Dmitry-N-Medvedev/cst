const std = @import("std");
const parseSingleLineSingleValueString = @import("../parsers/parseSingleLineSingleValueString.zig").parseSingleLineSingleValueString;
const Token = @import("../Token.zig").Token;
const TokenError = @import("../Token.zig").TokenError;
const TokenAccessValue = @import("../Token.zig").TokenAccessValue;
const token = @tagName(Token.ACCESS);

pub fn processTokenACCESS(line: []const u8) !?TokenAccessValue {
    const result = try parseSingleLineSingleValueString(token, line);

    if (result.len == 0) {
        return TokenError.EmptyValue;
    }

    return std.meta.stringToEnum(TokenAccessValue, result);
}

test "OK" {
    const line = @tagName(Token.ACCESS) ++ " \t  " ++ @tagName(TokenAccessValue.D);
    const actualTokenAccessValue = try processTokenACCESS(line);

    try std.testing.expectEqual(TokenAccessValue.D, actualTokenAccessValue);
}

test "fail on empty value" {
    const line = @tagName(Token.ACCESS);

    try std.testing.expectError(TokenError.EmptyValue, processTokenACCESS(line));
}

test "fail on KeyNotFound" {
    const line = "RANDOM_KEY \t RANDOM_VALUE";

    try std.testing.expectError(TokenError.KeyNotFound, processTokenACCESS(line));
}
