const std = @import("std");
const zigfsm = @import("zigfsm");
const Token = @import("domain/Token.zig").Token;
const TokenOrder = @import("domain/Token.zig").TokenOrder;
const TokenAccessValue = @import("domain/Token.zig").TokenAccessValue;
const TokenFormValue = @import("domain/Token.zig").TokenFormValue;
const TokenVarUnitValue = @import("domain/Token.zig").TokenVarUnitValue;
const TokenAxiUnitValue = @import("domain/Token.zig").TokenAxiUnitValue;
const parseSingleLineStingleStringValue = @import("parserFunctions/parseSingleLineSingleStringValue.zig").parseSingleLineSingleStringValue;

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

const Parser = struct {
    handler: FSM.Handler,
    fsm: *FSM,
    input: []const u8,
    input_idx: usize,
    allocator: std.mem.Allocator,
    result: *Result,
    current_token: Token,

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
        while (self.input_idx < self.input.len) : (self.input_idx += 1) {
            self.current_token = resolveToken(self.input, &self.input_idx).?;

            std.debug.print("self.current_token: {any}; input_idx: {d}\n", .{ self.current_token, self.input_idx });

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
                else => {
                    // std.debug.print("switch ELSE:\t{any}\n", .{self.current_token});
                },
            }
        }
    }

    fn resolveToken(input: []const u8, input_idx: *usize) ?Token {
        var foundToken: Token = undefined;
        //
        const whitespace = " \t\r\n";
        const next_space_pos = std.mem.indexOfAny(u8, input, whitespace).?;
        std.debug.print("next_space_pos: {d}\n", .{next_space_pos});
        //
        for (TokenOrder) |token| {
            const tokenString = @tagName(token);
            const nextPos = input_idx.* + tokenString.len;
            std.debug.print("probing for {s}\t'{s}'; input_idx..nextPos: [{d}..{d}]\n", .{ tokenString, input[input_idx.*..nextPos], input_idx.*, nextPos });

            if (nextPos > input.len) {
                std.debug.print("nextPos > input.len: {d} > {d}\n", .{ nextPos, input.len });

                unreachable;
            }

            if (std.mem.eql(u8, tokenString, input[input_idx.*..nextPos])) {
                std.debug.print("found '{any}'\t[{d}..{d}]\n", .{ token, input_idx.*, nextPos - 1 });
                input_idx.* = nextPos;
                foundToken = token;

                break;
            }
        }

        return foundToken;
    }

    pub fn onTransition(handler: *FSM.Handler, event: ?Event, from: State, to: State) zigfsm.HandlerResult {
        const self = zigfsm.Interface.downcast(@This(), handler);

        std.debug.print("[ {any} ] ==({any})==> [ {any} ]\n", .{ from, event, to });

        switch (to) {
            State.INITIAL => unreachable,
            State.FILE => {
                const fileName = parseSingleLineStingleStringValue(self.input, &self.input_idx);
                self.result.FILE.appendSlice(fileName) catch unreachable;
            },
            State.ACCESS => {
                const accessValue = parseSingleLineStingleStringValue(self.input, &self.input_idx);
                const accessToken = std.meta.stringToEnum(TokenAccessValue, accessValue).?;
                self.result.ACCESS = accessToken;
            },
            State.FORM => {
                const formValue = parseSingleLineStingleStringValue(self.input, &self.input_idx);
                const formTokenValue = std.meta.stringToEnum(TokenFormValue, formValue).?;
                self.result.FORM = formTokenValue;
            },
            State.RECL => {
                const reclValue = parseSingleLineStingleStringValue(self.input, &self.input_idx);
                self.result.RECL = std.fmt.parseInt(u8, reclValue, 10) catch unreachable;
            },
            State.FORMAT => {
                const formatValue = parseSingleLineStingleStringValue(self.input, &self.input_idx);
                self.result.FORMAT = formatValue;
            },
            State.CONTENT => {
                const contentValue = parseSingleLineStingleStringValue(self.input, &self.input_idx);
                self.result.CONTENT = contentValue;
            },
            State.CONFIG => {
                const configValue = parseSingleLineStingleStringValue(self.input, &self.input_idx);
                self.result.CONFIG = configValue;
            },
            State.NDIMENS => {
                const ndimensValue = parseSingleLineStingleStringValue(self.input, &self.input_idx);
                self.result.NDIMENS = std.fmt.parseInt(u8, ndimensValue, 10) catch unreachable;
            },
            else => {
                std.debug.print(".onTransition::[ELSE]\n", .{});
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
        // const genlab = result.*.GENLAB;
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
            // \\ .GENLAB: {s}
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
            // genlab,
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
