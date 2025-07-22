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
pub const TokenAxiUnitValue = enum { L, T };
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

pub const GENERATED_LENGTHS: []const usize = blk: {
    const all = std.enums.values(Token);
    var seen = std.StaticBitSet(256).initEmpty();
    var buf: [all.len]usize = undefined;
    var count: usize = 0;
    for (all) |t| {
        const len: usize = @intCast(@tagName(t).len);
        if (!seen.isSet(len)) {
            seen.set(len);
            buf[count] = len;
            count += 1;
        }
    }
    const final: [count]usize = buf[0..count].*;
    break :blk &final;
};

pub const TokenTable = struct {
    comptime lengths: []const usize = GENERATED_LENGTHS,
    comptime tokens_by_length: [GENERATED_MATRIX.len][]const Token = GENERATED_MATRIX,

    const Self = @This();

    pub fn getByLen(self: TokenTable, len: usize) []const Token {
        if (len < self.tokens_by_length.len) {
            return self.tokens_by_length[len];
        }
        return &[_]Token{};
    }
};

test "find Token" {
    const tt = TokenTable{};
    const input = "FILE\t startup.$41\r\n";
    const whitespace = " \t\r\n";
    const next_space_pos = std.mem.indexOfAny(u8, input, whitespace).?;

    const TimeMeasurementReport = struct {
        getByLen: u64 = undefined,
        tokenResolveLoop: u64 = undefined,
    };

    var timer = try std.time.Timer.start();
    const tokens = tt.getByLen(next_space_pos);
    var measurementReport: TimeMeasurementReport = TimeMeasurementReport{};
    measurementReport.getByLen = timer.read();

    timer.reset();
    for (tokens) |t| {
        if (std.mem.startsWith(u8, input, @tagName(t))) {
            measurementReport.tokenResolveLoop = timer.read();
            // std.debug.print("token: {any}\n", .{t});
            break;
        }
    }

    const timeer_report =
        \\ get: {d} ns
        \\ for: {d} ns
    ;
    const r = try std.fmt.allocPrint(std.testing.allocator, timeer_report, .{ measurementReport.getByLen, measurementReport.tokenResolveLoop });
    defer std.testing.allocator.free(r);
    // std.debug.print("time measurements:\n{s}\n", .{r});
}
