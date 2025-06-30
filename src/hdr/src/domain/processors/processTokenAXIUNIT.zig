const std = @import("std");
const parseSingleLineSingleValueString = @import("../parsers/parseSingleLineSingleValueString.zig").parseSingleLineSingleValueString;
const Token = @import("../Token.zig").Token;
const TokenError = @import("../Token.zig").TokenError;
const AxiUnitValue = @import("../Token.zig").AxiUnitValue;
const token = @tagName(Token.AXIUNIT);

pub fn processTokenAXIUNIT(line: []const u8) !?AxiUnitValue {
    const result = try parseSingleLineSingleValueString(token, line);

    if (result.len == 0) {
        return TokenError.EmptyValue;
    }

    return std.meta.stringToEnum(AxiUnitValue, result);
}

test "OK" {
    const line = @tagName(Token.AXIUNIT) ++ " \t  " ++ @tagName(AxiUnitValue.L);
    const actualTokenAxiUnitValue = try processTokenAXIUNIT(line);

    try std.testing.expectEqual(AxiUnitValue.L, actualTokenAxiUnitValue);
}

test "fail on empty value" {
    const line = @tagName(Token.AXIUNIT);

    try std.testing.expectError(TokenError.EmptyValue, processTokenAXIUNIT(line));
}

test "fail on KeyNotFound" {
    const line = "RANDOM_KEY \t L";

    try std.testing.expectError(TokenError.KeyNotFound, processTokenAXIUNIT(line));
}
