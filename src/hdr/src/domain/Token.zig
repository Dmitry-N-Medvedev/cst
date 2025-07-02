const std = @import("std");

pub const TokenError = error{
    // keys
    KeyNotFound,

    // values
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
};

pub const TokenAccessValue = enum {
    D,
};

pub const TokenFormValue = enum {
    F,
};

// TODO: inconsistent name of the enum. Must be TokenAxiUnitValue
pub const AxiUnitValue = enum {
    L,
};

pub const TokenVarUnitValue = enum {
    F,
    FL,
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
