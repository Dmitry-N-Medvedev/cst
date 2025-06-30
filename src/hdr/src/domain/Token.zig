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
};

pub const TokenAccessValue = enum {
    D,
};

pub const TokenFormValue = enum {
    F,
};

pub const AxiUnitValue = enum {
    L,
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
