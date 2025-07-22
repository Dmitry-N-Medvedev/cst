const std = @import("std");
const Whitespace = @import("WhiteSpace.zig").Whitespace;
const TokenVarUnitValue = @import("../domain/Token.zig").TokenVarUnitValue;

pub fn parseMultiValue(comptime T: type, allocator: std.mem.Allocator, input: []const u8, pos: *usize, stop: []const u8) !T {
    const stop_pos_rel = std.mem.indexOf(u8, input[pos.*..], stop) orelse unreachable;
    const stop_pos_abs = pos.* + stop_pos_rel;
    const data = input[pos.*..stop_pos_abs];
    defer {
        pos.* = stop_pos_abs;
    }
    const trimmed = std.mem.trim(u8, data, Whitespace);
    var items = std.ArrayList([]const u8).init(allocator);
    defer items.deinit();

    var items_iter = std.mem.splitAny(u8, trimmed, Whitespace);
    while (items_iter.next()) |value| {
        if (value.len == 0) {
            continue;
        }

        items.append(value) catch unreachable;
    }

    return switch (T) {
        []u16 => {
            var result = std.ArrayList(u16).init(allocator);
            defer result.deinit();

            for (items.items) |value| {
                const unsigned = std.fmt.parseUnsigned(u16, value, 10) catch unreachable;
                result.append(unsigned) catch unreachable;
            }

            return allocator.dupe(u16, result.items) catch unreachable;
        },
        []f64 => {
            var result = std.ArrayList(f64).init(allocator);
            defer result.deinit();

            for (items.items) |value| {
                const float = std.fmt.parseFloat(f64, value) catch unreachable;
                result.append(float) catch unreachable;
            }

            return allocator.dupe(f64, result.items) catch unreachable;
        },
        []TokenVarUnitValue => {
            var result = std.ArrayList(TokenVarUnitValue).init(allocator);
            defer result.deinit();

            for (items.items) |value| {
                const token = std.meta.stringToEnum(TokenVarUnitValue, value) orelse {
                    std.debug.print("unknown TokenVarUnitValue: {s}\n", .{value});
                    unreachable;
                };
                result.append(token) catch unreachable;
            }

            return allocator.dupe(TokenVarUnitValue, result.items) catch unreachable;
        },
        []const []const u8 => {
            var result = std.ArrayList([]const u8).init(allocator);
            defer result.deinit();

            for (items.items) |value| {
                result.append(value) catch unreachable;
            }

            return allocator.dupe([]const u8, result.items) catch unreachable;
        },
        else => @compileError("unsupported type" ++ @typeName(T)),
    };
}

test "OK" {
    const Token = @import("../domain/Token.zig").Token;
    const EOL = @import("EOL.zig").EOL;
    const value_type = []f64;
    const allocator = std.testing.allocator;
    var pos: usize = @tagName(Token.ULOADS).len;
    const stop = @tagName(Token.MAXTIME);
    var expected_values = std.ArrayList(f64).init(allocator);
    defer expected_values.deinit();

    try expected_values.appendSlice(&.{
        6.9981980e+06,  4.2721165e+06,  8.1991310e+06, 2.9385547e+04,  8.5319492e+04,  -2.7001578e+05, 2.8317475e+05, 1.5648267e+05,
        -6.7034210e+06, -4.1654075e+05, 6.7163500e+06, -7.6692078e+04, -2.1516912e+04, 2.6505691e+05,  2.6592884e+05, -7.7241763e+03,
        -7.5435556e+05, 6.5005205e+06,  6.5441440e+06, -7.5505219e+04, 2.5805048e+05,  3.0578367e+04,  2.5985589e+05, 5.0441215e+04,
        -5.9513435e+06, -6.4868413e+05, 5.9865915e+06, -6.6004563e+04, -3.0234969e+04, 2.3735881e+05,  2.3927675e+05, 1.2165750e+05,
        6.9931370e+06,  4.2886930e+06,  8.2034660e+06, 2.8999766e+04,  8.6213758e+04,  -2.6973941e+05, 2.8318219e+05, 1.6872928e+05,
        1.7544512e+04,  4.5657838e+05,  4.5691531e+05, -7.3072626e+02, 1.1642125e+04,  -3.2469058e+03, 1.2086417e+04, -2.5167284e+05,
        6.5448465e+06,  7.4669625e+05,  6.5873040e+06, 6.5867797e+04,  1.9038943e+04,  -2.5869916e+05, 2.5939880e+05, -4.1329008e+04,
        -7.7263988e+05, 6.4353315e+06,  6.4815480e+06, -7.7948672e+04, 2.5567506e+05,  3.0947748e+04,  2.5754127e+05, 6.2204801e+04,
        -7.5758975e+05, 6.4997140e+06,  6.5437165e+06, -7.5553703e+04, 2.5805541e+05,  3.0647717e+04,  2.5986895e+05, 5.0584711e+04,
        -5.9647755e+06, -6.4860713e+05, 5.9999370e+06, -6.6171031e+04, -3.0241328e+04, 2.3786272e+05,  2.3977742e+05, 1.2069999e+05,
        -6.7008925e+06, -4.2851766e+05, 6.7145805e+06, -7.6599828e+04, -2.1955000e+04, 2.6509344e+05,  2.6600103e+05, -3.9531511e+03,
        6.9981980e+06,  4.2721165e+06,  8.1991310e+06, 2.9385547e+04,  8.5319492e+04,  -2.7001578e+05, 2.8317475e+05, 1.5648267e+05,
        6.9976460e+06,  4.2803750e+06,  8.2029665e+06, 2.9206000e+04,  8.5766813e+04,  -2.6998863e+05, 2.8328397e+05, 1.6259778e+05,
        -2.5493594e+04, 4.5691897e+05,  4.5762959e+05, -1.1291042e+03, 1.1592393e+04,  -1.4846276e+03, 1.1687073e+04, -2.5166536e+05,
        2.5765802e+05,  4.6493725e+06,  4.6565065e+06, -1.8856184e+04, 1.1133510e+05,  -1.9527382e+03, 1.1135223e+05, 4.2475038e+05,
        -6.8082086e+04, 4.6224588e+05,  4.6723272e+05, -9.4548401e+02, 1.1765028e+04,  2.4370433e+02,  1.1767552e+04, -2.5173898e+05,
    });

    var output = std.ArrayList(u8).init(allocator);
    defer output.deinit();
    var writer = output.writer();

    var buffer: [64]u8 = undefined;
    try writer.print("{s} ", .{@tagName(Token.ULOADS)});
    for (expected_values.items, 0..) |expected_value, i| {
        const formatted_value = try std.fmt.formatFloat(&buffer, expected_value, .{ .mode = .scientific, .precision = 7 });

        try writer.print(" ", .{});

        if ((i + 1) % 8 == 0) {
            try writer.print("{s}", .{EOL.RN.value()});
        }

        try writer.print("{s}", .{formatted_value});
    }
    try writer.print("{s}", .{EOL.RN.value()});
    try writer.print("{s}   2.2870000E+02   0.0000000E+00   2.2880000E+02   1.2185000E+02   2.5000000E-01   9.9100001E+01   2.2875000E+02   2.9815000E+02{s}", .{ stop, EOL.RN.value() });

    const input = output.toOwnedSlice() catch unreachable;
    defer allocator.free(input);
    const resolved_values = parseMultiValue(value_type, allocator, input, &pos, stop) catch unreachable;
    defer allocator.free(resolved_values);

    for (resolved_values, 0..) |resolved_value, i| {
        try std.testing.expectEqual(expected_values.items[i], resolved_value);
    }
}
