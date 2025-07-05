const std = @import("std");
const Token = @import("../Token.zig").Token;
const TokenError = @import("../Token.zig").TokenError;

pub inline fn parseMultiLineMultiValue(allocator: std.mem.Allocator, token: Token, line: []const u8) !std.ArrayList([]const u8) {
    if (!std.mem.startsWith(u8, line, @tagName(token))) {
        return TokenError.KeyNotFound;
    }

    var result = std.ArrayList([]const u8).init(allocator);
    errdefer result.deinit();

    var entries = std.mem.tokenizeAny(u8, line[@tagName(token).len..], &[_]u8{' '});
    while (entries.next()) |entry| {
        try result.append(entry);
    }

    if (result.items.len == 0) {
        return TokenError.EmptyValue;
    }

    return result;
}

test "OK" {
    const allocator = std.testing.allocator;
    var expected_values = std.ArrayList(f64).init(allocator);
    defer expected_values.deinit();

    const num_of_cols = 8;
    var i: usize = 0;
    while (i < 16) : (i += 1) {
        try expected_values.append(6.9981980E+06);
        try expected_values.append(4.2721165E+06);
        try expected_values.append(8.1991310E+06);
        try expected_values.append(2.9385547E+04);
        try expected_values.append(8.5319492E+04);
        try expected_values.append(-2.7001578E+05);
        try expected_values.append(2.8317475E+05);
        try expected_values.append(1.5648267E+05);
    }

    var line = try std.ArrayList(u8).initCapacity(allocator, expected_values.items.len);

    try line.appendSlice(@tagName(Token.ULOADS));
    try line.append('\t');
    try line.append(' ');

    var last_item_id = expected_values.items.len;
    var buffer: [64]u8 = undefined;

    for (expected_values.items, 1..) |expected_value, j| {
        try line.appendSlice(try std.fmt.bufPrint(&buffer, "{:<14}", .{expected_value}));

        if (j < last_item_id) {
            try line.append(' ');
        }

        if (j % num_of_cols == 0) {
            try line.append('\r');
            try line.append('\n');
            try line.append(' ');
            try line.append(' ');
        }
    }

    try line.append('\r');
    try line.append('\n');

    var maxtime_values = try std.ArrayList(f64).initCapacity(allocator, num_of_cols);
    defer maxtime_values.deinit();

    try maxtime_values.append(2.2870000E+02);
    try maxtime_values.append(0.0000000E+00);
    try maxtime_values.append(2.2880000E+02);
    try maxtime_values.append(1.2185000E+02);
    try maxtime_values.append(2.5000000E-01);
    try maxtime_values.append(9.9100001E+01);
    try maxtime_values.append(2.2875000E+02);
    try maxtime_values.append(2.9815000E+02);

    try line.appendSlice(@tagName(Token.MAXTIME));
    try line.append('\t');
    try line.append(' ');

    last_item_id = maxtime_values.items.len;
    for (maxtime_values.items, 0..) |maxtime_value, j| {
        try line.appendSlice(try std.fmt.bufPrint(&buffer, "{:<14}", .{maxtime_value}));

        if (j < last_item_id) {
            try line.append(' ');
        }
    }

    try line.append('\r');
    try line.append('\n');

    const s = try line.toOwnedSlice();
    defer allocator.free(s);

    std.debug.print("s: {s}", .{s});
}

// test "empty value" {
//     const allocator = std.testing.allocator;
//
//     try std.testing.expectError(TokenError.EmptyValue, parseMultiLineMultiValue(allocator, Token.DIMENS, @tagName(Token.DIMENS)));
// }
//
// test "fail TokenError.KeyNotFoundError" {
//     const allocator = std.testing.allocator;
//
//     try std.testing.expectError(TokenError.KeyNotFound, parseMultiLineMultiValue(allocator, Token.DIMENS, "ARBITRARY_KEY \t ARBITRARY_VALUE"));
// }

// test "fail empty line" {
//     const allocator = std.testing.allocator;
//
//     try std.testing.expectError(TokenError.KeyNotFound, parseSingleLineMultiValue(allocator, @tagName(Token.DIMENS), ""));
// }
