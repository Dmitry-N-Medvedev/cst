const std = @import("std");
const Token = @import("../Token.zig").Token;
const TokenVarUnitValue = @import("../Token.zig").TokenVarUnitValue;
const TokenError = @import("../Token.zig").TokenError;
const parseSingleLineMultiValue = @import("../parsers/parseSingleLineMultiValue.zig").parseSingleLineMultiValue;

pub fn processTokenMAXTIME(allocator: std.mem.Allocator, line: []const u8) !std.ArrayList(f64) {
    const array = try parseSingleLineMultiValue(allocator, Token.MAXTIME, line);
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

    try expected_values.append(2.2870000E+02);
    try expected_values.append(0.0000000E+00);
    try expected_values.append(2.2880000E+02);
    try expected_values.append(1.2185000E+02);
    try expected_values.append(2.5000000E-01);
    try expected_values.append(9.9100001E+01);
    try expected_values.append(2.2875000E+02);
    try expected_values.append(2.9815000E+02);

    var line = std.ArrayList(u8).init(allocator);
    defer line.deinit();

    try line.appendSlice(@tagName(Token.MAXTIME));
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

    const result = try processTokenMAXTIME(allocator, s);
    defer result.deinit();

    try std.testing.expectEqual(expected_values.items.len, result.items.len);

    for (expected_values.items, 0..) |expected_value, i| {
        try std.testing.expectEqual(expected_value, result.items[i]);
    }
}

test "fail on TokenError.InvalidTypeValue" {
    const allocator = std.testing.allocator;
    var line = std.ArrayList(u8).init(allocator);
    try line.appendSlice(@tagName(Token.MAXTIME));
    try line.append('\t');
    try line.append(' ');
    try line.append('Z');

    const s = try line.toOwnedSlice();
    defer allocator.free(s);

    try std.testing.expectError(TokenError.InvalidTypeValue, processTokenMAXTIME(allocator, s));
}

test "fail on empty value" {
    const allocator = std.testing.allocator;
    var line = std.ArrayList(u8).init(allocator);
    try line.appendSlice(@tagName(Token.MAXTIME));
    try line.append('\t');
    try line.append(' ');

    const s = try line.toOwnedSlice();
    defer allocator.free(s);

    try std.testing.expectError(TokenError.EmptyValue, processTokenMAXTIME(allocator, s));
}
