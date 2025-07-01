const std = @import("std");
const TokenError = @import("../Token.zig").TokenError;
const parseSingleLineSingleValue = @import("../parsers/parseSingleLineSingleValue.zig").parseSingleLineSingleValue;
const Token = @import("../Token.zig").Token;

pub fn processTokenFILE(line: []const u8) ![]const u8 {
    const result = try parseSingleLineSingleValue(Token.FILE, line);

    if (result.len == 0) {
        return TokenError.EmptyValue;
    }

    return result;
}

test "OK" {
    const expected_file_name = "startup.$41";
    const line = @tagName(Token.FILE) ++ " \t  " ++ expected_file_name;
    const resolved_file_name = try processTokenFILE(line);

    try std.testing.expectEqualStrings(expected_file_name, resolved_file_name);
}

test "fail on empty value" {
    const line = @tagName(Token.FILE);

    try std.testing.expectError(TokenError.EmptyValue, processTokenFILE(line));
}
