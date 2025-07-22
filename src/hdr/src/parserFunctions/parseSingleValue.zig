const std = @import("std");
const Whitespace = @import("WhiteSpace.zig").Whitespace;
const TokenAxiUnitValue = @import("../domain/Token.zig").TokenAxiUnitValue;

// generic single value parser
pub fn parseSingleValue(comptime T: type, input: []const u8, pos: *usize, stop: []const u8) !T {
    const stop_pos_rel = std.mem.indexOf(u8, input[pos.*..], stop) orelse unreachable;
    const stop_pos_abs = pos.* + stop_pos_rel;
    defer {
        pos.* = stop_pos_abs;
    }
    const data = input[pos.*..stop_pos_abs];
    const trimmed = std.mem.trim(u8, data, Whitespace);

    return switch (T) {
        []const u8 => trimmed,
        u8 => std.fmt.parseInt(u8, trimmed, 10),
        f64 => std.fmt.parseFloat(f64, trimmed),
        TokenAxiUnitValue => std.meta.stringToEnum(TokenAxiUnitValue, trimmed) orelse unreachable,
        else => @compileError("unsupported type" ++ @typeName(T)),
    };
}
