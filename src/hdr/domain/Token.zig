const std = @import("std");

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

    pub fn fromString(s: []const u8) ?Token {
        return std.meta.stringToEnum(Token, s);
    }
};

pub const TokenOrder: [23]Token = .{
    .FILE,
    .ACCESS,
    .FORM,
    .RECL,
    .FORMAT,
    .CONTENT,
    .CONFIG,
    .NDIMENS,
    .DIMENS,
    .GENLAB,
    .VARIAB,
    .VARUNIT,
    .AXISLAB,
    .AXIUNIT,
    .AXIMETH,
    .AXIVAL,
    .AXISLAB,
    .AXIUNIT,
    .AXIMETH,
    .MIN,
    .STEP,
    .NVARS,
    .ULOADS,
};
