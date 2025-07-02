const std = @import("std");
const Token = @import("../Token.zig").Token;
const TokenError = @import("../Token.zig").TokenError;
const parseSingleLineMultiValue = @import("../parsers/parseSingleLineMultiValue.zig").parseSingleLineMultiValue;

const TOKEN = Token.VARIAB;

pub fn processTokenVARIAB(allocator: std.mem.Allocator, line: []const u8) !std.ArrayList([]const u8) {
    const array = try parseSingleLineMultiValue(allocator, TOKEN, line);

    return array;
}

test "OK" {
    const allocator = std.testing.allocator;
    var expected_values = std.ArrayList([]const u8).init(allocator);
    defer expected_values.deinit();

    try expected_values.append("'Blade 1 Mx (Root axes)'");
    try expected_values.append("'Blade 1 Mx (Root axes)'");
    try expected_values.append("'Blade 1 My (Root axes)'");
    try expected_values.append("'Blade 1 Mxy (Root axes)'");
    try expected_values.append("'Blade 1 Mz (Root axes)'");
    try expected_values.append("'Blade 1 Fx (Root axes)'");
    try expected_values.append("'Blade 1 Fy (Root axes)'");
    try expected_values.append("'Blade 1 Fxy (Root axes)'");
    try expected_values.append("'Blade 1 Fz (Root axes)'");

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

    const result = try processTokenVARIAB(allocator, s);
    defer result.deinit();

    try std.testing.expectEqual(expected_values.items.len, result.items.len);

    const tick = &[_]u8{'\''};
    for (expected_values.items, 0..) |expected_item, i| {
        var start_idx: usize = undefined;
        var end_idx: usize = undefined;

        if (std.mem.startsWith(u8, expected_item, tick) and
            std.mem.endsWith(u8, expected_item, tick))
        {
            start_idx = 1;
            end_idx = expected_item.len - 1;
        } else {
            start_idx = 0;
            end_idx = expected_item.len;
        }
        const expected_value = expected_item[start_idx..end_idx];
        try std.testing.expectEqualStrings(expected_value, result.items[i]);
    }
}
