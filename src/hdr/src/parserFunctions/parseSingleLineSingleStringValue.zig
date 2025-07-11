const std = @import("std");

const RN = "\r\n";

pub inline fn parseSingleLineSingleStringValue(input: []const u8, pos: *usize) []const u8 {
    const new_line_pos = pos.* + std.mem.indexOf(u8, input[pos.*..], RN).?;
    const result = std.mem.trim(u8, input[pos.*..new_line_pos], &.{ ' ', '\t', '\'' });

    pos.* = new_line_pos + RN.len;

    return result;
}

test "OK" {
    const allocator = std.testing.allocator;
    var values = std.ArrayList([]const u8).init(allocator);
    defer values.deinit();

    try values.appendSlice(&[_][]const u8{
        "startup.$41",
        "D",
        "F",
        "4",
        "R*4",
        "START",
        "TRANSIENT",
        "8 44 6001",
    });

    for (values.items) |value| {
        var pos: usize = 0;
        const input = try std.fmt.allocPrint(allocator, "\t {s}\r\n", .{value});
        defer allocator.free(input);
        const expected_pos = input.len;

        const result = parseSingleLineSingleStringValue(input, &pos);

        // std.debug.print("value: '{s}'\tresult: '{s}'; expocted_pos: {d}; pos: {d}\n", .{ value, result, expected_pos, pos });

        try std.testing.expectEqualStrings(value, result);
        try std.testing.expectEqual(expected_pos, pos);
    }
}
