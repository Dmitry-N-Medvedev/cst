const std = @import("std");
const Token = @import("../Token.zig").Token;
const TokenError = @import("../Token.zig").TokenError;
const parseSingleLineMultiValue = @import("../parsers/parseSingleLineMultiValue.zig").parseSingleLineMultiValue;

const TOKEN = Token.DIMENS;

pub const Dimensions = struct {
    TimeSeriesLength: u16 = 6001,
    VARIAB: u8 = 0,
    AXIVAL: u8 = 0,
};
pub fn processTokenDIMENS(allocator: std.mem.Allocator, line: []const u8) !Dimensions {
    const array = try parseSingleLineMultiValue(allocator, TOKEN, line);
    defer array.deinit();

    const result: Dimensions = .{
        .VARIAB = try std.fmt.parseInt(u8, array.items[0], 10),
        .AXIVAL = try std.fmt.parseInt(u8, array.items[1], 10),
        .TimeSeriesLength = try std.fmt.parseInt(u16, array.items[2], 10),
    };

    return result;
}

test "OK" {
    const allocator = std.testing.allocator;
    const line: []const u8 = @tagName(TOKEN) ++ "\t 8 44 6001";
    const dimensions: Dimensions = try processTokenDIMENS(allocator, line);

    try std.testing.expectEqual(8, dimensions.VARIAB);
    try std.testing.expectEqual(44, dimensions.AXIVAL);
    try std.testing.expectEqual(6001, dimensions.TimeSeriesLength);
}
