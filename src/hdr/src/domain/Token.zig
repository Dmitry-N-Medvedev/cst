const std = @import("std");

pub const TokenError = error{
    // keys
    KeyNotFound,

    // values
    EmptyValue,
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

    pub fn from_string(s: []const u8) ?Token {
        return std.meta.stringToEnum(Token, s);
    }
};

pub const TokenAccessValue = enum {
    D,

    pub fn from_string(s: []const u8) ?TokenAccessValue {
        return std.meta.stringToEnum(TokenAccessValue, s);
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
