const std = @import("std");
const ParseError = @import("ParseError.zig").ParseError;
const EOL = @import("EOL.zig").EOL;

pub inline fn parseSingleLineSingleStringValue(input: []const u8, pos: *usize, eol: EOL) ParseError![]const u8 {
    const eol_val = eol.value();
    const eol_len = eol_val.len;
    const rel_eol_pos: usize = switch (eol_len) {
        1 => std.mem.indexOfScalar(u8, input[pos.*..], eol_val[0]) orelse return ParseError.NotFoundEOL,
        2 => std.mem.indexOf(u8, input[pos.*..], eol_val) orelse return ParseError.NotFoundEOL,
        else => return ParseError.UnsupportedEOL,
    };
    const abs_eol_pos = rel_eol_pos + pos.*;

    // std.debug.print(".parseSingleLineSingleStringValue: pos: {d} eol: {any} rel_eol_pos: {d} abs_eol_pos: {d}\n", .{ pos.*, eol, rel_eol_pos, abs_eol_pos });

    const result = std.mem.trim(u8, input[pos.*..abs_eol_pos], &.{ ' ', '\t' });

    pos.* = abs_eol_pos + eol_len;

    return result;
}

test "parseSingleLineSingleStringValue::OK" {
    const allocator = std.testing.allocator;
    var expected_values = std.ArrayList([]const u8).init(allocator);
    defer expected_values.deinit();

    const EOL_Record = struct {
        value: EOL,
        description: []const u8,
    };
    var tails = std.ArrayList(EOL_Record).init(allocator);
    defer tails.deinit();

    try tails.appendSlice(&[_]EOL_Record{
        EOL_Record{ .value = EOL.R, .description = "Old MacOS" },
        EOL_Record{ .value = EOL.N, .description = "Unix/Linux/Modern MacOS" },
        EOL_Record{ .value = EOL.RN, .description = "Windows" },
    });

    try expected_values.appendSlice(&[_][]const u8{
        "startup.$41",
        "D",
        "F",
        "4",
        "R*4",
        "START",
        "TRANSIENT",
        "'START'",
        "'TRANSIENT'",
        "8 44 6001",
    });

    const input_prefix = "\t ";

    for (tails.items) |tail| {
        std.debug.print("EOL: {s}\n", .{tail.description});

        for (expected_values.items) |expected_value| {
            var actual_pos: usize = 0;
            const input = try std.fmt.allocPrint(allocator, "{s}{s}{s}IRRELEVANT_KEY IRRELEVANT_VALUE{s}", .{ input_prefix, expected_value, tail.value.value(), tail.value.value() });
            defer allocator.free(input);
            const expected_pos = input_prefix.len + expected_value.len + tail.value.value().len;

            const actual_value = try parseSingleLineSingleStringValue(input, &actual_pos, tail.value);

            // std.debug.print("actual_value: {s}\n", .{actual_value});

            try std.testing.expectEqualStrings(expected_value, actual_value);
            try std.testing.expectEqual(expected_pos, actual_pos);
        }
    }
}

// test "parseSingleLineSingleStringValue: expect unreachable on no EOL" {
//     const allocator = std.testing.allocator;
//     const input = try std.fmt.allocPrint(allocator, "\t startup.$41", .{});
//     defer allocator.free(input);
//     var pos: usize = 0;
//
//     try std.testing.expectError(ParseError.NotFoundEOL, parseSingleLineSingleStringValue(input, &pos, EOL.R));
// }
