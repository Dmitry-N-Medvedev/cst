const std = @import("std");
const zigfsm = @import("zigfsm");
const Token = @import("domain/Token.zig").Token;
const TokenTable = @import("domain/Token.zig").TokenTable;
const TokenOrder = @import("domain/Token.zig").TokenOrder;
const TokenAccessValue = @import("domain/Token.zig").TokenAccessValue;
const TokenFormValue = @import("domain/Token.zig").TokenFormValue;
const TokenVarUnitValue = @import("domain/Token.zig").TokenVarUnitValue;
const TokenAxiUnitValue = @import("domain/Token.zig").TokenAxiUnitValue;
const parseSingleLineStingleStringValue = @import("parserFunctions/parseSingleLineSingleStringValue.zig").parseSingleLineSingleStringValue;
const parseMultiLineMultiValue = @import("parserFunctions/parseMultiLineMultiValue.zig").parseMultiLineMultiValue;
const EOL = @import("parserFunctions/EOL.zig").EOL;
const Whitespace = @import("parserFunctions/WhiteSpace.zig").Whitespace;

const State = enum {
    INITIAL,
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
    //
    EOF,
};

const Event = enum {
    SIG_PARSE,
    //
    SIG_FILE,
    SIG_ACCESS,
    SIG_FORM,
    SIG_RECL,
    SIG_FORMAT,
    SIG_CONTENT,
    SIG_CONFIG,
    SIG_NDIMENS,
    SIG_DIMENS,
    SIG_GENLAB,
    SIG_VARIAB,
    SIG_VARUNIT,
    SIG_AXIVAL,
    SIG_AXISLAB,
    SIG_AXIUNIT,
    SIG_AXIMETH,
    SIG_MIN,
    SIG_STEP,
    SIG_NVARS,
    SIG_ULOADS,
    SIG_MAXTIME,
    SIG_MINTIME,
    SIG_MEAN,
    //
    SIG_EOF,
};

const transition_table = [_]zigfsm.Transition(State, Event){
    .{ .event = .SIG_FILE, .from = .INITIAL, .to = .FILE },
    .{ .event = .SIG_ACCESS, .from = .FILE, .to = .ACCESS },
    .{ .event = .SIG_FORM, .from = .ACCESS, .to = .FORM },
    .{ .event = .SIG_RECL, .from = .FORM, .to = .RECL },
    .{ .event = .SIG_FORMAT, .from = .RECL, .to = .FORMAT },
    .{ .event = .SIG_CONTENT, .from = .FORMAT, .to = .CONTENT },
    .{ .event = .SIG_CONFIG, .from = .CONTENT, .to = .CONFIG },
    .{ .event = .SIG_NDIMENS, .from = .CONFIG, .to = .NDIMENS },
    .{ .event = .SIG_DIMENS, .from = .NDIMENS, .to = .DIMENS },
    .{ .event = .SIG_GENLAB, .from = .DIMENS, .to = .GENLAB },
    .{ .event = .SIG_VARIAB, .from = .GENLAB, .to = .VARIAB },
    .{ .event = .SIG_VARUNIT, .from = .VARIAB, .to = .VARUNIT },
    .{ .event = .SIG_AXISLAB, .from = .VARUNIT, .to = .AXISLAB },
    .{ .event = .SIG_AXIUNIT, .from = .AXISLAB, .to = .AXIUNIT },
    .{ .event = .SIG_AXIMETH, .from = .AXIUNIT, .to = .AXIMETH },
    .{ .event = .SIG_MIN, .from = .AXIMETH, .to = .MIN },
    .{ .event = .SIG_STEP, .from = .MIN, .to = .STEP },
    .{ .event = .SIG_NVARS, .from = .STEP, .to = .NVARS },
    .{ .event = .SIG_AXIVAL, .from = .AXIMETH, .to = .AXIVAL },
    .{ .event = .SIG_AXISLAB, .from = .AXIVAL, .to = .AXISLAB },
    .{ .event = .SIG_ULOADS, .from = .NVARS, .to = .ULOADS },
    .{ .event = .SIG_MAXTIME, .from = .ULOADS, .to = .MAXTIME },
    .{ .event = .SIG_MINTIME, .from = .MAXTIME, .to = .MINTIME },
    .{ .event = .SIG_MEAN, .from = .MINTIME, .to = .MEAN },
    .{ .event = .SIG_ULOADS, .from = .MEAN, .to = .ULOADS },
    .{ .event = .SIG_EOF, .from = .MEAN, .to = .EOF },
};

const Result = struct {
    FILE: std.ArrayList(u8),
    ACCESS: TokenAccessValue = undefined,
    FORM: TokenFormValue = undefined,
    RECL: ?u8 = undefined,
    FORMAT: []const u8 = undefined,
    CONTENT: []const u8 = &[_]u8{},
    CONFIG: []const u8 = &[_]u8{},
    NDIMENS: u8 = undefined,
    DIMENS: []u16 = &[_]u16{},
    GENLAB: []const u8 = &[_]u8{},
    VARIAB: []const u8 = &[_]u8{},
    VARUNIT: []const TokenVarUnitValue = &[_]TokenVarUnitValue{},
    AXISLAB: std.ArrayList([]const u8),
    AXIUNIT: std.ArrayList([]const TokenAxiUnitValue),
    AXIMETH: u8 = undefined,
    MIN: f64 = undefined,
    STEP: f64 = undefined,
    NVARS: u8 = undefined,
    ULOADS: std.ArrayList([]const f64),
    MAXTIME: std.ArrayList([]const f64),
    MINTIME: std.ArrayList([]const f64),
    MEAN: std.ArrayList([]const f64),

    pub fn init(allocator: std.mem.Allocator) !Result {
        return Result{
            .FILE = std.ArrayList(u8).init(allocator),
            .AXISLAB = std.ArrayList([]const u8).init(allocator),
            .AXIUNIT = std.ArrayList([]const TokenAxiUnitValue).init(allocator),
            .ULOADS = std.ArrayList([]const f64).init(allocator),
            .MAXTIME = std.ArrayList([]const f64).init(allocator),
            .MINTIME = std.ArrayList([]const f64).init(allocator),
            .MEAN = std.ArrayList([]const f64).init(allocator),
        };
    }

    pub fn deinit(self: *@This()) void {
        self.FILE.deinit();
        self.AXISLAB.deinit();
        self.AXIUNIT.deinit();
        self.ULOADS.deinit();
        self.MAXTIME.deinit();
        self.MINTIME.deinit();
        self.MEAN.deinit();
    }
};

const FSM = zigfsm.StateMachineFromTable(State, Event, &transition_table, State.INITIAL, &[_]State{State.EOF});

const tokenInfo = @typeInfo(Token).@"enum";
const tokenFields = tokenInfo.fields;
const tt: TokenTable = TokenTable{};

const Parser = struct {
    handler: FSM.Handler,
    fsm: *FSM,
    input: []const u8,
    input_idx: usize,
    allocator: std.mem.Allocator,
    result: *Result,
    current_token: Token,
    default_EOL: EOL = EOL.RN,

    pub fn parse(fsm: *FSM, input: []const u8, result: *Result) !void {
        var instance: @This() = .{
            .handler = zigfsm.Interface.make(FSM.Handler, @This()),
            .fsm = fsm,
            .input = input,
            .input_idx = 0,
            .allocator = std.heap.page_allocator,
            .result = result,
            .current_token = undefined,
        };

        instance.fsm.setTransitionHandlers(&.{&instance.handler});

        try instance.execute();
    }

    fn execute(self: *@This()) !void {
        while (self.input_idx < self.input.len) {
            std.debug.print("[0] SELF.INPUT_IDX: {d}\n", .{self.input_idx});
            self.current_token = resolveKey(self.input, &self.input_idx).?;
            std.debug.print("[1] SELF.INPUT_IDX: {d} self.current_token: {any}\n", .{ self.input_idx, self.current_token });

            switch (self.current_token) {
                Token.FILE => {
                    _ = try self.fsm.do(Event.SIG_FILE);
                },
                Token.ACCESS => {
                    _ = try self.fsm.do(Event.SIG_ACCESS);
                },
                Token.FORM => {
                    _ = try self.fsm.do(Event.SIG_FORM);
                },
                Token.RECL => {
                    _ = try self.fsm.do(Event.SIG_RECL);
                },
                Token.FORMAT => {
                    _ = try self.fsm.do(Event.SIG_FORMAT);
                },
                Token.CONTENT => {
                    _ = try self.fsm.do(Event.SIG_CONTENT);
                },
                Token.CONFIG => {
                    _ = try self.fsm.do(Event.SIG_CONFIG);
                },
                Token.NDIMENS => {
                    _ = try self.fsm.do(Event.SIG_NDIMENS);
                },
                Token.DIMENS => {
                    _ = try self.fsm.do(Event.SIG_DIMENS);
                },
                Token.GENLAB => {
                    _ = try self.fsm.do(Event.SIG_GENLAB);
                },
                Token.VARIAB => {
                    _ = try self.fsm.do(Event.SIG_VARIAB);
                },
                Token.VARUNIT => {
                    _ = try self.fsm.do(Event.SIG_VARUNIT);
                },
                Token.AXISLAB => {
                    _ = try self.fsm.do(Event.SIG_AXISLAB);
                },
                Token.AXIUNIT => {
                    _ = try self.fsm.do(Event.SIG_AXIUNIT);
                },
                Token.AXIMETH => {
                    _ = try self.fsm.do(Event.SIG_AXIMETH);
                },
                Token.AXIVAL => {
                    _ = try self.fsm.do(Event.SIG_AXIVAL);
                },
                Token.MIN => {
                    _ = try self.fsm.do(Event.SIG_MIN);
                },
                Token.STEP => {
                    _ = try self.fsm.do(Event.SIG_STEP);
                },
                Token.NVARS => {
                    _ = try self.fsm.do(Event.SIG_NVARS);
                },
                Token.ULOADS => {
                    _ = try self.fsm.do(Event.SIG_ULOADS);
                },
                Token.MAXTIME => {
                    _ = try self.fsm.do(Event.SIG_MAXTIME);
                },
                Token.MINTIME => {
                    _ = try self.fsm.do(Event.SIG_MAXTIME);
                },
                Token.MEAN => {
                    _ = try self.fsm.do(Event.SIG_MEAN);
                },
            }

            std.debug.print("[2] SELF.INPUT_IDX: {d} self.current_token: {any}\n", .{ self.input_idx, self.current_token });
        }
    }

    fn resolveKey(input: []const u8, input_idx: *usize) ?Token {
        const rel_space_pos = std.mem.indexOfAny(u8, input[input_idx.*..], Whitespace) orelse unreachable;
        const abs_space_pos = input_idx.* + rel_space_pos;
        const tokenLength = abs_space_pos - input_idx.*;
        const haystack = input[input_idx.*..abs_space_pos];
        const tokens = tt.getByLen(tokenLength);

        if (tokens.len == 0) {
            std.debug.print("ERR .resolveKey:\n\tinput_idx: {d}\n\ttokenLength: {d}\n\thaystack: {s}\n\ttokens: {any}\n", .{ input_idx.*, tokenLength, haystack, tokens });
            unreachable;
        }

        for (tokens) |tokenFound| {
            if (std.mem.eql(u8, haystack, @tagName(tokenFound))) {
                input_idx.* = abs_space_pos;

                std.debug.print("OK .resolveKey:\n\tinput_idx: {d}\n\ttokenLength: {d}\n\thaystack: {s}\n\ttokens: {any}\n", .{ input_idx.*, tokenLength, haystack, tokens });
                return tokenFound;
            }
        }

        unreachable;
    }

    pub fn onTransition(handler: *FSM.Handler, event: ?Event, from: State, to: State) zigfsm.HandlerResult {
        const self = zigfsm.Interface.downcast(@This(), handler);

        std.debug.print("[ {any} ] ==({any})==> [ {any} ]\n", .{ from, event, to });

        switch (to) {
            State.INITIAL => unreachable,
            State.FILE => {
                const fileName = parseSingleLineStingleStringValue(self.input, &self.input_idx, self.default_EOL) catch unreachable;
                self.result.FILE.appendSlice(fileName) catch unreachable;

                std.debug.print("State.FILE:\n\tfileName: {s}\n\tinput_idx: {d}\n\tcurrent_token: {any}\n", .{ fileName, self.input_idx, self.current_token });
            },
            State.ACCESS => {
                const accessValue = parseSingleLineStingleStringValue(self.input, &self.input_idx, self.default_EOL) catch unreachable;
                const accessToken = std.meta.stringToEnum(TokenAccessValue, accessValue).?;
                self.result.ACCESS = accessToken;

                std.debug.print("State.ACCESS:\n\taccessValue: {s}\n\taccessToken: {any}\n\tcurrent_token: {any}\n\tself.input_idx: {d}\n", .{ accessValue, accessToken, self.current_token, self.input_idx });
            },
            State.FORM => {
                const formValue = parseSingleLineStingleStringValue(self.input, &self.input_idx, self.default_EOL) catch unreachable;
                const formTokenValue = std.meta.stringToEnum(TokenFormValue, formValue).?;
                self.result.FORM = formTokenValue;
            },
            State.RECL => {
                const reclValue = parseSingleLineStingleStringValue(self.input, &self.input_idx, self.default_EOL) catch unreachable;
                self.result.RECL = std.fmt.parseInt(u8, reclValue, 10) catch unreachable;
            },
            State.FORMAT => {
                const formatValue = parseSingleLineStingleStringValue(self.input, &self.input_idx, self.default_EOL) catch unreachable;
                self.result.FORMAT = formatValue;
            },
            State.CONTENT => {
                const contentValue = parseSingleLineStingleStringValue(self.input, &self.input_idx, self.default_EOL) catch unreachable;
                self.result.CONTENT = contentValue;
            },
            State.CONFIG => {
                const configValue = parseSingleLineStingleStringValue(self.input, &self.input_idx, self.default_EOL) catch unreachable;
                self.result.CONFIG = configValue;
            },
            State.NDIMENS => {
                const ndimensValue = parseSingleLineStingleStringValue(self.input, &self.input_idx, self.default_EOL) catch unreachable;
                self.result.NDIMENS = std.fmt.parseInt(u8, ndimensValue, 10) catch unreachable;
            },
            State.DIMENS => {
                _ = parseSingleLineStingleStringValue(self.input, &self.input_idx, self.default_EOL) catch unreachable;
            },
            State.GENLAB => {
                const genlabValue = parseSingleLineStingleStringValue(self.input, &self.input_idx, self.default_EOL) catch unreachable;
                self.result.GENLAB = genlabValue;
            },
            State.VARIAB => {
                _ = parseSingleLineStingleStringValue(self.input, &self.input_idx, self.default_EOL) catch unreachable;
            },
            State.VARUNIT => {
                _ = parseSingleLineStingleStringValue(self.input, &self.input_idx, self.default_EOL) catch unreachable;
            },
            State.AXISLAB => {
                _ = parseSingleLineStingleStringValue(self.input, &self.input_idx, self.default_EOL) catch unreachable;
            },
            State.AXIUNIT => {
                _ = parseSingleLineStingleStringValue(self.input, &self.input_idx, self.default_EOL) catch unreachable;
            },
            State.AXIMETH => {
                _ = parseSingleLineStingleStringValue(self.input, &self.input_idx, self.default_EOL) catch unreachable;
            },
            State.AXIVAL => {
                _ = parseSingleLineStingleStringValue(self.input, &self.input_idx, self.default_EOL) catch unreachable;
            },
            State.MIN => {
                _ = parseSingleLineStingleStringValue(self.input, &self.input_idx, self.default_EOL) catch unreachable;
            },
            State.STEP => {
                _ = parseSingleLineStingleStringValue(self.input, &self.input_idx, self.default_EOL) catch unreachable;
            },
            State.NVARS => {
                _ = parseSingleLineStingleStringValue(self.input, &self.input_idx, self.default_EOL) catch unreachable;
            },
            State.ULOADS => {
                const uloadsValue = parseMultiLineMultiValue(self.allocator, self.input, &self.input_idx, self.default_EOL) catch unreachable;
                std.debug.print("ULOAD:\n{any}\n", .{uloadsValue});
            },
            State.MAXTIME => {
                _ = parseSingleLineStingleStringValue(self.input, &self.input_idx, self.default_EOL) catch unreachable;
            },
            State.MINTIME => {
                _ = parseSingleLineStingleStringValue(self.input, &self.input_idx, self.default_EOL) catch unreachable;
            },
            State.MEAN => {
                _ = parseSingleLineStingleStringValue(self.input, &self.input_idx, self.default_EOL) catch unreachable;
            },
            else => {
                unreachable;
            },
        }

        return zigfsm.HandlerResult.Continue;
    }

    fn printResult(allocator: std.mem.Allocator, result: *Result) !void {
        const file = if (result.FILE.items.len > 0) result.FILE.items else "N/A";
        const access = @tagName(result.ACCESS);
        const form = @tagName(result.FORM);
        const recl = [1]u8{result.RECL orelse ' '};
        const format = result.FORMAT;
        const content = result.CONTENT;
        const config = result.CONFIG;
        const ndimens = result.NDIMENS;
        // const dimens = result.DIMENS;
        const genlab = result.*.GENLAB;
        // const variab = result.*.VARIAB;
        // const varunit = result.*.VARUNIT;
        // const axislab = result.*.AXISLAB;
        // const axiunit = result.*.AXIUNIT;
        // const aximeth = result.*.AXIMETH;
        // const min = result.*.MIN;
        // const step = result.*.STEP;
        // const nvars = result.*.NVARS;
        // const uloads = result.*.ULOADS;
        // const maxtime = result.*.MAXTIME;
        // const mintime = result.*.MINTIME;
        // const mean = result.*.MEAN;

        const template =
            \\ .FILE: {s}
            \\ .ACCESS: {s}
            \\ .FORM: {s}
            \\ .RECL: {s}
            \\ .FORMAT: {s}
            \\ .CONTENT: {s}
            \\ .CONFIG: {s}
            \\ .NDIMENS: {d}
            // \\ .DIMENS: {d}
            \\ .GENLAB: {s}
            // \\ .VARIAB: {s}
            // \\ .VARUNIT: {s}
            // \\ .AXISLAB: {s}
            // \\ .AXIUNIT: {s}
            // \\ .AXIMETH: {s}
            // \\ .MIN: {d}
            // \\ .STEP: {d}
            // \\ .NVARS: {d}
            // \\ .ULOADS: {s}
            // \\ .MAXTIME: {s}
            // \\ .MINTIME: {s}
            // \\ .MEAN: {s}
        ;
        const r = try std.fmt.allocPrint(allocator, template, .{
            file,
            access,
            form,
            recl,
            format,
            content,
            config,
            ndimens,
            // dimens,
            genlab,
            // variab,
            // varunit,
            // axislab,
            // axiunit,
            // aximeth,
            // min,
            // step,
            // nvars,
            // uloads,
            // maxtime,
            // mintime,
            // mean,
        });
        defer allocator.free(r);

        std.debug.print("\nRESULT:\n{s}\n\n", .{r});
    }
};

// test "OK" {
//     const allocator = std.testing.allocator;
//     const specs = try std.fs.cwd().openFile("src/.data/startup.%41", .{ .mode = .read_only });
//     defer specs.close();
//
//     const contents = try specs.readToEndAlloc(allocator, std.math.maxInt(usize));
//     defer allocator.free(contents);
//     std.debug.print("contents.len: {d}\n", .{contents.len});
//
//     var result: Result = try Result.init(allocator);
//     defer result.deinit();
//
//     var fsm = FSM.init();
//     try Parser.parse(&fsm, contents, &result);
//
//     try Parser.printResult(allocator, &result);
//
//     // const fileName = try result.FILE.toOwnedSlice();
//     // defer allocator.free(fileName);
//
//     // try std.testing.expectEqualStrings("startup.$41", fileName);
//     try std.testing.expect(true);
// }
