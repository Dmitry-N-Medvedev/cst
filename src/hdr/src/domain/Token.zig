const std = @import("std");

pub const TokenError = error{
    KeyNotFound,
    EmptyValue,
    UnknownValue,
    InvalidTypeValue,
};

pub const Token = enum {
    FILE,
    ACCESS,
    FORM,
    RECL,
    FORMAT,
    CONTENT,
    CONFIG,
    NDIMENS,
    DIMENS,
    GENLAB,
    VARIAB,
    VARUNIT,
    AXIVAL,
    AXISLAB,
    AXIUNIT,
    AXIMETH,
    MIN,
    STEP,
    NVARS,
    ULOADS,
    MAXTIME,
    MINTIME,
    MEAN,
};

pub const TokenAccessValue = enum { D };
pub const TokenFormValue = enum { F };
pub const TokenAxiUnitValue = enum { L };
pub const TokenVarUnitValue = enum { F, FL };

pub const TokenAxisLabValue = enum {
    @"Distance from hub center",
    Time,
    @"Distance along blade",
    @"Tower height",
    @"Tower station height",
};

pub const TokenOrder: [26]Token = .{
    .NDIMENS, .CONTENT, .MAXTIME, .MINTIME, .CONFIG,  .ACCESS,  .FORMAT,
    .VARIAB,  .VARUNIT, .AXIVAL,  .AXISLAB, .AXISLAB, .AXIUNIT, .AXIUNIT,
    .AXIMETH, .AXIMETH, .DIMENS,  .GENLAB,  .ULOADS,  .NVARS,   .FILE,
    .FORM,    .RECL,    .MEAN,    .MIN,     .STEP,
};

pub const GENERATED_MATRIX = blk: {
    const all = std.enums.values(Token);

    var slice_storage: [256][]const Token = undefined;

    const buckets = blk_buckets: {
        var tmp: [256][]const Token = undefined;

        @setEvalBranchQuota(10000);
        for (0..256) |len| {
            var buf: [all.len]Token = undefined;
            var count: usize = 0;

            for (all) |tok| {
                if (@tagName(tok).len == len) {
                    buf[count] = tok;
                    count += 1;
                }
            }

            const arr: [count]Token = buf[0..count].*;
            tmp[len] = &arr;
        }

        break :blk_buckets tmp;
    };

    slice_storage = buckets;
    break :blk slice_storage;
};

pub const GENERATED_LENGTHS: []const u8 = blk: {
    const all = std.enums.values(Token);
    var seen = std.StaticBitSet(256).initEmpty();
    var buf: [all.len]u8 = undefined;
    var count: usize = 0;
    for (all) |t| {
        const len: u8 = @intCast(@tagName(t).len);
        if (!seen.isSet(len)) {
            seen.set(len);
            buf[count] = len;
            count += 1;
        }
    }
    const final: [count]u8 = buf[0..count].*;
    break :blk &final;
};

pub const TokenTable = struct {
    comptime lengths: []const u8 = GENERATED_LENGTHS,
    comptime tokens_by_length: [GENERATED_MATRIX.len][]const Token = GENERATED_MATRIX,

    const Self = @This();

    pub fn getByLen(self: TokenTable, len: u8) []const Token {
        if (len < self.tokens_by_length.len) {
            return self.tokens_by_length[len];
        }
        return &[_]Token{};
    }
};

test "TokenTable" {
    const tt = TokenTable{};

    for (tt.lengths) |l| {
        const tokens = tt.getByLen(l);

        for (tokens) |t| {
            try std.testing.expectEqual(l, @tagName(t).len);
            std.debug.print("{any} {d}\n", .{ t, l });
        }
    }
}
