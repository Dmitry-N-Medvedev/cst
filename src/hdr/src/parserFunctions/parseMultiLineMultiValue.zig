const std = @import("std");
const ParseError = @import("ParseError.zig").ParseError;
const EOL = @import("EOL.zig").EOL;
const Token = @import("../domain/Token.zig").Token;
const Whitespace = @import("WhiteSpace.zig").Whitespace;

const MAXTIME = @tagName(Token.MAXTIME);

pub inline fn parseMultiLineMultiValue(allocator: std.mem.Allocator, input: []const u8, pos: *usize) ParseError![]const []const u8 {
    const maxtime_pos = std.mem.indexOf(u8, input[pos.*..], MAXTIME) orelse unreachable;
    const value_slice = input[pos.*..maxtime_pos];
    var values = std.mem.splitAny(u8, value_slice, Whitespace);

    var result = std.ArrayList([]const u8).init(allocator);
    defer result.deinit();

    while (values.next()) |entry| {
        if (entry.len == 0) {
            continue;
        }

        result.append(entry) catch unreachable;
    }

    pos.* += maxtime_pos;

    return result.toOwnedSlice() catch unreachable;
}

test "parseMultiLineMultiValue::OK" {
    const allocator = std.testing.allocator;

    const uloads =
        \\ 6.9981980E+06   4.2721165E+06   8.1991310E+06   2.9385547E+04   8.5319492E+04  -2.7001578E+05   2.8317475E+05   1.5648267E+05
        \\ -6.7034210E+06  -4.1654075E+05   6.7163500E+06  -7.6692078E+04  -2.1516912E+04   2.6505691E+05   2.6592884E+05  -7.7241763E+03
        \\ -7.5435556E+05   6.5005205E+06   6.5441440E+06  -7.5505219E+04   2.5805048E+05   3.0578367E+04   2.5985589E+05   5.0441215E+04
        \\ -5.9513435E+06  -6.4868413E+05   5.9865915E+06  -6.6004563E+04  -3.0234969E+04   2.3735881E+05   2.3927675E+05   1.2165750E+05
        \\ 6.9931370E+06   4.2886930E+06   8.2034660E+06   2.8999766E+04   8.6213758E+04  -2.6973941E+05   2.8318219E+05   1.6872928E+05
        \\ 1.7544512E+04   4.5657838E+05   4.5691531E+05  -7.3072626E+02   1.1642125E+04  -3.2469058E+03   1.2086417E+04  -2.5167284E+05
        \\ 6.5448465E+06   7.4669625E+05   6.5873040E+06   6.5867797E+04   1.9038943E+04  -2.5869916E+05   2.5939880E+05  -4.1329008E+04
        \\ -7.7263988E+05   6.4353315E+06   6.4815480E+06  -7.7948672E+04   2.5567506E+05   3.0947748E+04   2.5754127E+05   6.2204801E+04
        \\ -7.5758975E+05   6.4997140E+06   6.5437165E+06  -7.5553703E+04   2.5805541E+05   3.0647717E+04   2.5986895E+05   5.0584711E+04
        \\ -5.9647755E+06  -6.4860713E+05   5.9999370E+06  -6.6171031E+04  -3.0241328E+04   2.3786272E+05   2.3977742E+05   1.2069999E+05
        \\ -6.7008925E+06  -4.2851766E+05   6.7145805E+06  -7.6599828E+04  -2.1955000E+04   2.6509344E+05   2.6600103E+05  -3.9531511E+03
        \\ 6.9981980E+06   4.2721165E+06   8.1991310E+06   2.9385547E+04   8.5319492E+04  -2.7001578E+05   2.8317475E+05   1.5648267E+05
        \\ 6.9976460E+06   4.2803750E+06   8.2029665E+06   2.9206000E+04   8.5766813E+04  -2.6998863E+05   2.8328397E+05   1.6259778E+05
        \\ -2.5493594E+04   4.5691897E+05   4.5762959E+05  -1.1291042E+03   1.1592393E+04  -1.4846276E+03   1.1687073E+04  -2.5166536E+05
        \\ 2.5765802E+05   4.6493725E+06   4.6565065E+06  -1.8856184E+04   1.1133510E+05  -1.9527382E+03   1.1135223E+05   4.2475038E+05
        \\ -6.8082086E+04   4.6224588E+05   4.6723272E+05  -9.4548401E+02   1.1765028E+04   2.4370433E+02   1.1767552E+04  -2.5173898E+05
        \\ MAXTIME   2.2870000E+02   0.0000000E+00   2.2880000E+02   1.2185000E+02   2.5000000E-01   9.9100001E+01   2.2875000E+02   2.9815000E+02
    ;

    var pos: usize = 0;
    const values = parseMultiLineMultiValue(allocator, uloads, &pos) catch unreachable;
    defer allocator.free(values);

    std.debug.print("pos: {d}\n", .{pos});

    for (values) |value| {
        std.debug.print("{s} ", .{value});
    }

    try std.testing.expect(true);
}

// test "parseSingleLineSingleStringValue: expect unreachable on no EOL" {
//     const allocator = std.testing.allocator;
//     const input = try std.fmt.allocPrint(allocator, "\t startup.$41", .{});
//     defer allocator.free(input);
//     var pos: usize = 0;
//
//     try std.testing.expectError(ParseError.NotFoundEOL, parseSingleLineSingleStringValue(input, &pos, EOL.R));
// }
