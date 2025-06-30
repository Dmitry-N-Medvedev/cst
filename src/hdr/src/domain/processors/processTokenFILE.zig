const std = @import("std");
const TokenError = @import("../Token.zig").TokenError;
const parseSingleLineSingleValueString = @import("../parsers/parseSingleLineSingleValueString.zig").parseSingleLineSingleValueString;
const FILE = @import("../Token.zig").Token.FILE;
const token = @tagName(FILE);

pub fn processTokenFILE(line: []const u8) ![]const u8 {
    const result = try parseSingleLineSingleValueString(token, line);

    if (result.len == 0) {
        return TokenError.EmptyValue;
    }

    return result;
}

test "OK" {
    const expected_file_name = "startup.$41";
    const line = @tagName(FILE) ++ " \t  " ++ expected_file_name;
    const resolved_file_name = try processTokenFILE(line);

    try std.testing.expectEqualStrings(expected_file_name, resolved_file_name);
}

test "fail on empty value" {
    const line = @tagName(FILE);

    try std.testing.expectError(TokenError.EmptyValue, processTokenFILE(line));
}
