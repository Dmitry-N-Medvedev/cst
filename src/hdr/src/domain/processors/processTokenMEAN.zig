const std = @import("std");
const Token = @import("../Token.zig").Token;
const TokenVarUnitValue = @import("../Token.zig").TokenVarUnitValue;
const TokenError = @import("../Token.zig").TokenError;
const parseSingleLineMultiValue = @import("../parsers/parseSingleLineMultiValue.zig").parseSingleLineMultiValue;

const TOKEN = Token.MEAN;

pub fn processTokenMINTIME(allocator: std.mem.Allocator, line: []const u8) !std.ArrayList(f64) {
    const array = try parseSingleLineMultiValue(allocator, TOKEN, line);
    defer array.deinit();

    var result = try std.ArrayList(f64).initCapacity(allocator, array.items.len);
    errdefer result.deinit();

    var value: f64 = undefined;
    for (array.items) |item| {
        value = std.fmt.parseFloat(f64, item) catch return TokenError.InvalidTypeValue;

        try result.append(value);
    }

    return result;
}

test "OK" {
    const allocator = std.testing.allocator;
    var expected_values = std.ArrayList(f64).init(allocator);
    defer expected_values.deinit();

    try expected_values.append(-5.1488525E+03);
    try expected_values.append(3.5717936E+06);
    try expected_values.append(5.5318302E+06);
    try expected_values.append(-2.3683847E+04);
    try expected_values.append(1.0215117E+05);
    try expected_values.append(3.7104863E+03);
    try expected_values.append(1.9543676E+05);
    try expected_values.append(1.1390940E+05);

    var line = std.ArrayList(u8).init(allocator);
    defer line.deinit();

    try line.appendSlice(@tagName(TOKEN));
    try line.append('\t');
    try line.append(' ');

    var buffer: [64]u8 = undefined;
    const last_item_id = expected_values.items.len - 1;
    for (expected_values.items, 0..) |item, i| {
        try line.appendSlice(try std.fmt.bufPrint(&buffer, "{d}", .{item}));
        if (i < last_item_id) {
            try line.append(' ');
        }
    }

    const s = try line.toOwnedSlice();
    defer allocator.free(s);

    const result = try processTokenMINTIME(allocator, s);
    defer result.deinit();

    try std.testing.expectEqual(expected_values.items.len, result.items.len);

    for (expected_values.items, 0..) |expected_value, i| {
        try std.testing.expectEqual(expected_value, result.items[i]);
    }
}

test "fail on TokenError.InvalidTypeValue" {
    const allocator = std.testing.allocator;
    var line = std.ArrayList(u8).init(allocator);
    try line.appendSlice(@tagName(TOKEN));
    try line.append('\t');
    try line.append(' ');
    try line.append('Z');

    const s = try line.toOwnedSlice();
    defer allocator.free(s);

    try std.testing.expectError(TokenError.InvalidTypeValue, processTokenMINTIME(allocator, s));
}

test "fail on empty value" {
    const allocator = std.testing.allocator;
    var line = std.ArrayList(u8).init(allocator);
    try line.appendSlice(@tagName(TOKEN));
    try line.append('\t');
    try line.append(' ');

    const s = try line.toOwnedSlice();
    defer allocator.free(s);

    try std.testing.expectError(TokenError.EmptyValue, processTokenMINTIME(allocator, s));
}
