const std = @import("std");
const parseSingleLineSingleValueString = @import("../parsers/parseSingleLineSingleValueString.zig").parseSingleLineSingleValueString;
const Token = @import("../Token.zig").Token;
const TokenError = @import("../Token.zig").TokenError;
const TokenFormValue = @import("../Token.zig").TokenFormValue;
const token = @tagName(Token.FORM);

pub fn processTokenFORM(line: []const u8) !?TokenFormValue {
    const result = try parseSingleLineSingleValueString(token, line);

    if (result.len == 0) {
        return TokenError.EmptyValue;
    }

    return std.meta.stringToEnum(TokenFormValue, result);
}

test "OK" {
    const line = @tagName(Token.FORM) ++ " \t  " ++ @tagName(TokenFormValue.F);
    const actualTokenFormValue = try processTokenFORM(line);

    try std.testing.expectEqual(TokenFormValue.F, actualTokenFormValue);
}

test "fail on empty value" {
    const line = @tagName(Token.FORM);

    try std.testing.expectError(TokenError.EmptyValue, processTokenFORM(line));
}

test "fail on KeyNotFound" {
    const line = "RANDOM_KEY \t RANDOM_VALUE";

    try std.testing.expectError(TokenError.KeyNotFound, processTokenFORM(line));
}
