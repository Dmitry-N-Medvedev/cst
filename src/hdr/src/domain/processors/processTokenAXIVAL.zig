const std = @import("std");
const Token = @import("../Token.zig").Token;
const TokenVarUnitValue = @import("../Token.zig").TokenVarUnitValue;
const TokenError = @import("../Token.zig").TokenError;
const parseSingleLineMultiValue = @import("../parsers/parseSingleLineMultiValue.zig").parseSingleLineMultiValue;

const TOKEN = Token.AXIVAL;

pub fn processTokenAXIVAL(allocator: std.mem.Allocator, line: []const u8) !std.ArrayList(f64) {
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

    try expected_values.append(0.0000000);
    try expected_values.append(0.2480000);
    try expected_values.append(0.6330011);
    try expected_values.append(1.7901800);
    try expected_values.append(3.7906139);
    try expected_values.append(5.1909809);
    try expected_values.append(6.6788540);
    try expected_values.append(8.3426723);
    try expected_values.append(10.0938902);
    try expected_values.append(12.0190401);
    try expected_values.append(13.1943903);
    try expected_values.append(16.3076496);
    try expected_values.append(19.3158798);
    try expected_values.append(20.9459705);
    try expected_values.append(23.4835701);
    try expected_values.append(26.1961002);
    try expected_values.append(28.6471691);
    try expected_values.append(31.2723198);
    try expected_values.append(34.1975517);
    try expected_values.append(36.6980019);
    try expected_values.append(39.4985695);
    try expected_values.append(42.1992798);
    try expected_values.append(45.1003990);
    try expected_values.append(47.9018288);
    try expected_values.append(50.2035484);
    try expected_values.append(53.7069206);
    try expected_values.append(56.1347618);
    try expected_values.append(58.2127304);
    try expected_values.append(61.3933907);
    try expected_values.append(63.9361916);
    try expected_values.append(66.4798965);
    try expected_values.append(68.8491211);
    try expected_values.append(71.1318665);
    try expected_values.append(72.7506027);
    try expected_values.append(75.4373322);
    try expected_values.append(77.3726501);
    try expected_values.append(79.2840729);
    try expected_values.append(80.8055801);
    try expected_values.append(82.3022995);
    try expected_values.append(83.7113037);
    try expected_values.append(84.8563538);
    try expected_values.append(85.8204117);
    try expected_values.append(85.9261322);
    try expected_values.append(86.1261292);

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

    const result = try processTokenAXIVAL(allocator, s);
    defer result.deinit();

    try std.testing.expectEqual(expected_values.items.len, result.items.len);

    for (expected_values.items, 0..) |expected_value, i| {
        try std.testing.expectEqual(expected_value, result.items[i]);
    }
}

test "fail on unknown TokenVarUnitValue" {
    const allocator = std.testing.allocator;
    var line = std.ArrayList(u8).init(allocator);
    try line.appendSlice(@tagName(TOKEN));
    try line.append('\t');
    try line.append(' ');
    try line.append('Z');

    const s = try line.toOwnedSlice();
    defer allocator.free(s);

    try std.testing.expectError(TokenError.InvalidTypeValue, processTokenAXIVAL(allocator, s));
}

test "fail on empty value" {
    const allocator = std.testing.allocator;
    var line = std.ArrayList(u8).init(allocator);
    try line.appendSlice(@tagName(TOKEN));
    try line.append('\t');
    try line.append(' ');

    const s = try line.toOwnedSlice();
    defer allocator.free(s);

    try std.testing.expectError(TokenError.EmptyValue, processTokenAXIVAL(allocator, s));
}
