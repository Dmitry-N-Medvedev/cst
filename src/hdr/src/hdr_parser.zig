const std = @import("std");
const T = @import("domain/Token.zig");
const Header = @import("domain/Header.zig").Header;
const ProcessFn = @import("domain/processors/ProcessFn.zig").ProcessFn;
const processFile = @import("domain/processors/processFILE.zig").processFILE;

fn getTokenProcessor(t: T.Token) ProcessFn {
    return switch (t) {
        .FILE => &processFile,
        .ACCESS, .AXIMETH, .AXISLAB, .AXIUNIT, .AXIVAL, .CONFIG, .CONTENT, .DIMENS, .FORM, .FORMAT, .GENLAB, .MIN, .NDIMENS, .NVARS, .RECL, .STEP, .ULOADS, .VARIAB, .VARUNIT => &processFile,
    };
}

fn parseHeaderBuffer(allocator: std.mem.Allocator, buffer: []const u8, header: *Header) !void {
    var tokensOrderPtr: usize = 0;
    var bufferPtr: usize = 0;
    while (tokensOrderPtr < T.TokenOrder.len) : ({
        tokensOrderPtr += 1;
    }) {
        const token: T.Token = T.TokenOrder[tokensOrderPtr];
        const processor = getTokenProcessor(token);
        const tokenValue: []const u8 = try processor(allocator, buffer, &bufferPtr);
        defer allocator.free(tokenValue);

        header.FILE = try allocator.dupe(u8, tokenValue);

        std.debug.print("token: {}\ttokenValue: {}\n", .{ token, tokenValue });
    }
}

pub fn main() !void {
    std.debug.print("hdr parser\n", .{});
}
