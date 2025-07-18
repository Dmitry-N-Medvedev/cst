const std = @import("std");
const parseSingleLineSingleValue = @import("../parsers/parseSingleLineSingleValue.zig").parseSingleLineSingleValue;
const Token = @import("../Token.zig").Token;
const TokenError = @import("../Token.zig").TokenError;
const TokenAccessValue = @import("../Token.zig").TokenAccessValue;

const TOKEN = Token.ACCESS;

pub fn processTokenACCESS(line: []const u8) !?TokenAccessValue {
    const result = try parseSingleLineSingleValue(TOKEN, line);

    if (result.len == 0) {
        return TokenError.EmptyValue;
    }

    return std.meta.stringToEnum(TokenAccessValue, result);
}

test "OK" {
    const line = @tagName(TOKEN) ++ " \t  " ++ @tagName(TokenAccessValue.D);
    const actualTokenAccessValue = try processTokenACCESS(line);

    try std.testing.expectEqual(TokenAccessValue.D, actualTokenAccessValue);
}

test "fail on empty value" {
    const line = @tagName(TOKEN);

    try std.testing.expectError(TokenError.EmptyValue, processTokenACCESS(line));
}

test "fail on KeyNotFound" {
    const line = "RANDOM_KEY \t RANDOM_VALUE";

    try std.testing.expectError(TokenError.KeyNotFound, processTokenACCESS(line));
}
