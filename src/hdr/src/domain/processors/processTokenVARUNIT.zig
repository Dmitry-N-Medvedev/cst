const std = @import("std");
const Token = @import("../Token.zig").Token;
const TokenVarUnitValue = @import("../Token.zig").TokenVarUnitValue;
const TokenError = @import("../Token.zig").TokenError;
const parseSingleLineMultiValue = @import("../parsers/parseSingleLineMultiValue.zig").parseSingleLineMultiValue;

const TOKEN = Token.VARUNIT;

pub fn processTokenVARUNIT(allocator: std.mem.Allocator, line: []const u8) !std.ArrayList(TokenVarUnitValue) {
    const array = try parseSingleLineMultiValue(allocator, TOKEN, line);
    defer array.deinit();

    var result = try std.ArrayList(TokenVarUnitValue).initCapacity(allocator, array.items.len);
    errdefer result.deinit();

    var item_to_enum: TokenVarUnitValue = undefined;
    for (array.items) |item| {
        item_to_enum = std.meta.stringToEnum(TokenVarUnitValue, item) orelse return TokenError.UnknownValue;
        try result.append(item_to_enum);
    }

    return result;
}

test "OK" {
    const allocator = std.testing.allocator;
    var expected_values = std.ArrayList([]const u8).init(allocator);
    defer expected_values.deinit();

    try expected_values.append("FL");
    try expected_values.append("FL");
    try expected_values.append("FL");
    try expected_values.append("FL");
    try expected_values.append("F");
    try expected_values.append("F");
    try expected_values.append("F");
    try expected_values.append("F");

    var line = std.ArrayList(u8).init(allocator);
    defer line.deinit();

    try line.appendSlice(@tagName(TOKEN));
    try line.append('\t');
    try line.append(' ');

    const last_item_id = expected_values.items.len - 1;
    for (expected_values.items, 0..) |item, i| {
        try line.appendSlice(item);
        if (i < last_item_id) {
            try line.append(' ');
        }
    }

    const s = try line.toOwnedSlice();
    defer allocator.free(s);

    const result = try processTokenVARUNIT(allocator, s);
    defer result.deinit();

    try std.testing.expectEqual(expected_values.items.len, result.items.len);

    var expected_value_as_enum: TokenVarUnitValue = undefined;
    for (expected_values.items, 0..) |expected_value, i| {
        expected_value_as_enum = std.meta.stringToEnum(TokenVarUnitValue, expected_value) orelse @panic("failed to convert expected_value to TokenVarUnitValue");

        try std.testing.expectEqual(expected_value_as_enum, result.items[i]);
    }
}

test "fail on unknown TokenVarUnitValue" {
    const allocator = std.testing.allocator;
    var expected_values = std.ArrayList([]const u8).init(allocator);
    defer expected_values.deinit();

    try expected_values.append("Z");

    var line = std.ArrayList(u8).init(allocator);
    try line.appendSlice(@tagName(TOKEN));
    try line.append('\t');
    try line.append(' ');
    try line.append('Z');

    const s = try line.toOwnedSlice();
    defer allocator.free(s);

    try std.testing.expectError(TokenError.UnknownValue, processTokenVARUNIT(allocator, s));
}
