const std = @import("std");
const zigfsm = @import("zigfsm");
const Token = @import("domain/Token.zig").Token;
const TokenTable = @import("domain/Token.zig").TokenTable;
const TokenOrder = @import("domain/Token.zig").TokenOrder;
const TokenAccessValue = @import("domain/Token.zig").TokenAccessValue;
const TokenFormValue = @import("domain/Token.zig").TokenFormValue;
const TokenVarUnitValue = @import("domain/Token.zig").TokenVarUnitValue;
const TokenAxiUnitValue = @import("domain/Token.zig").TokenAxiUnitValue;
const parseSingleValue = @import("parserFunctions/parseSingleValue.zig").parseSingleValue;
const parseMultiValue = @import("parserFunctions/parseMultiValue.zig").parseMultiValue;
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
    VARIAB: []const []const u8 = &[_][]const u8{},
    VARUNIT: []const TokenVarUnitValue = &[_]TokenVarUnitValue{},
    AXISLAB: std.ArrayList([]const u8),
    AXIUNIT: std.ArrayList(TokenAxiUnitValue),
    AXIMETH: u8 = undefined,
    AXIVAL: []const f64 = undefined,
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
            .AXIUNIT = std.ArrayList(TokenAxiUnitValue).init(allocator),
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
    input_pos: usize,
    allocator: std.mem.Allocator,
    result: *Result,
    current_token: Token,
    default_EOL: EOL = EOL.RN,

    pub fn parse(fsm: *FSM, input: []const u8, result: *Result) !void {
        var instance: @This() = .{
            .handler = zigfsm.Interface.make(FSM.Handler, @This()),
            .fsm = fsm,
            .input = input,
            .input_pos = 0,
            .allocator = std.heap.page_allocator,
            .result = result,
            .current_token = undefined,
        };

        instance.fsm.setTransitionHandlers(&.{&instance.handler});

        try instance.execute();
    }

    fn execute(self: *@This()) !void {
        while (self.input_pos < self.input.len) {
            self.current_token = resolveKey(self.input, &self.input_pos).?;

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
                    _ = try self.fsm.do(Event.SIG_MINTIME);
                },
                Token.MEAN => {
                    _ = try self.fsm.do(Event.SIG_MEAN);
                },
            }
        }

        _ = try self.fsm.do(Event.SIG_EOF);
    }

    fn resolveKey(input: []const u8, pos: *usize) ?Token {
        const rel_space_pos = std.mem.indexOfAny(u8, input[pos.*..], Whitespace) orelse unreachable;

        if (rel_space_pos == 0) {
            std.debug.print("ERR: .resolveKey::unreachable: {d} {s}\n", .{ pos.*, input[pos.*..] });
            unreachable;
        }
        const abs_space_pos = pos.* + rel_space_pos;
        const tokenLength = abs_space_pos - pos.*;
        const haystack = input[pos.*..abs_space_pos];

        const tokens = tt.getByLen(tokenLength);

        if (tokens.len == 0) {
            std.debug.print("ERR .resolveKey:\n\tinput_pos: {d}\n\ttokenLength: {d}\n\thaystack: '{s}'\n\ttokens: {any}\n", .{ pos.*, tokenLength, haystack, tokens });
            unreachable;
        }

        for (tokens) |tokenFound| {
            if (std.mem.eql(u8, haystack, @tagName(tokenFound))) {
                // const prev_pos = pos.*;

                pos.* = abs_space_pos;

                // std.debug.print(".resolveKey: {s}\tpos: {d} => {d} [δ = {d}]\n", .{ @tagName(tokenFound), prev_pos, pos.*, tokenLength });
                return tokenFound;
            }
        }

        unreachable;
    }

    pub fn onTransition(handler: *FSM.Handler, event: ?Event, from: State, to: State) zigfsm.HandlerResult {
        _ = event;
        _ = from;
        const self = zigfsm.Interface.downcast(@This(), handler);

        // std.debug.print("[ {any} ] ==({any})==> [ {any} ]\n", .{ from, event, to });

        switch (to) {
            State.INITIAL => unreachable,
            State.FILE => {
                const value = parseSingleValue([]const u8, self.input, &self.input_pos, self.default_EOL.value()) catch unreachable;
                self.input_pos += self.default_EOL.value().len;
                self.result.FILE.appendSlice(value) catch unreachable;
            },
            State.ACCESS => {
                const value = parseSingleValue([]const u8, self.input, &self.input_pos, self.default_EOL.value()) catch unreachable;
                self.input_pos += self.default_EOL.value().len;
                const token = std.meta.stringToEnum(TokenAccessValue, value).?;
                self.result.ACCESS = token;
            },
            State.FORM => {
                const value = parseSingleValue([]const u8, self.input, &self.input_pos, self.default_EOL.value()) catch unreachable;
                const formTokenValue = std.meta.stringToEnum(TokenFormValue, value).?;
                self.input_pos += self.default_EOL.value().len;
                self.result.FORM = formTokenValue;
            },
            State.RECL => {
                const value = parseSingleValue(u8, self.input, &self.input_pos, self.default_EOL.value()) catch unreachable;
                self.input_pos += self.default_EOL.value().len;
                self.result.RECL = value;
            },
            State.FORMAT => {
                const value = parseSingleValue([]const u8, self.input, &self.input_pos, self.default_EOL.value()) catch unreachable;
                self.input_pos += self.default_EOL.value().len;
                self.result.FORMAT = value;
            },
            State.CONTENT => {
                const value = parseSingleValue([]const u8, self.input, &self.input_pos, self.default_EOL.value()) catch unreachable;
                self.input_pos += self.default_EOL.value().len;
                self.result.CONTENT = value;
            },
            State.CONFIG => {
                const value = parseSingleValue([]const u8, self.input, &self.input_pos, self.default_EOL.value()) catch unreachable;
                self.input_pos += self.default_EOL.value().len;
                self.result.CONFIG = value;
            },
            State.NDIMENS => {
                const value = parseSingleValue(u8, self.input, &self.input_pos, self.default_EOL.value()) catch unreachable;
                self.input_pos += self.default_EOL.value().len;
                self.result.NDIMENS = value;
            },
            State.DIMENS => {
                const value = parseMultiValue([]u16, self.allocator, self.input, &self.input_pos, self.default_EOL.value()) catch unreachable;
                self.input_pos += self.default_EOL.value().len;
                self.result.DIMENS = value;
            },
            State.GENLAB => {
                const value = parseSingleValue([]const u8, self.input, &self.input_pos, self.default_EOL.value()) catch unreachable;
                self.input_pos += self.default_EOL.value().len;
                self.result.GENLAB = value;
            },
            State.VARIAB => {
                const value = parseMultiValue([]const []const u8, self.allocator, self.input, &self.input_pos, self.default_EOL.value()) catch unreachable;
                self.input_pos += self.default_EOL.value().len;
                self.result.VARIAB = value;
            },
            State.VARUNIT => {
                const value = parseMultiValue([]TokenVarUnitValue, self.allocator, self.input, &self.input_pos, self.default_EOL.value()) catch unreachable;
                self.input_pos += self.default_EOL.value().len;
                self.result.VARUNIT = value;
            },
            State.AXISLAB => {
                const value = parseSingleValue([]const u8, self.input, &self.input_pos, self.default_EOL.value()) catch unreachable;
                self.input_pos += self.default_EOL.value().len;
                self.result.AXISLAB.append(value) catch unreachable;
            },
            State.AXIUNIT => {
                const value = parseSingleValue(TokenAxiUnitValue, self.input, &self.input_pos, self.default_EOL.value()) catch unreachable;
                self.input_pos += self.default_EOL.value().len;
                self.result.AXIUNIT.append(value) catch unreachable;
            },
            State.AXIMETH => {
                const value = parseSingleValue(u8, self.input, &self.input_pos, self.default_EOL.value()) catch unreachable;
                self.input_pos += self.default_EOL.value().len;
                self.result.AXIMETH = value;
            },
            State.AXIVAL => {
                const value = parseMultiValue([]f64, self.allocator, self.input, &self.input_pos, self.default_EOL.value()) catch unreachable;
                self.input_pos += self.default_EOL.value().len;
                self.result.AXIVAL = value;
            },
            State.MIN => {
                const value = parseSingleValue(f64, self.input, &self.input_pos, self.default_EOL.value()) catch unreachable;
                self.input_pos += self.default_EOL.value().len;
                self.result.MIN = value;
            },
            State.STEP => {
                const value = parseSingleValue(f64, self.input, &self.input_pos, self.default_EOL.value()) catch unreachable;
                self.input_pos += self.default_EOL.value().len;
                self.result.STEP = value;
            },
            State.NVARS => {
                const value = parseSingleValue(u8, self.input, &self.input_pos, self.default_EOL.value()) catch unreachable;
                self.input_pos += self.default_EOL.value().len;
                self.result.NVARS = value;
            },
            State.ULOADS => {
                const value = parseMultiValue([]f64, self.allocator, self.input, &self.input_pos, @tagName(Token.MAXTIME)) catch unreachable;
                // self.input_pos += @tagName(Token.MAXTIME).len;
                self.result.ULOADS.append(value) catch unreachable;
            },
            State.MAXTIME => {
                const value = parseMultiValue([]f64, self.allocator, self.input, &self.input_pos, self.default_EOL.value()) catch unreachable;
                self.input_pos += self.default_EOL.value().len;
                self.result.MAXTIME.append(value) catch unreachable;
            },
            State.MINTIME => {
                const value = parseMultiValue([]f64, self.allocator, self.input, &self.input_pos, self.default_EOL.value()) catch unreachable;
                self.input_pos += self.default_EOL.value().len;
                self.result.MINTIME.append(value) catch unreachable;
            },
            State.MEAN => {
                const value = parseMultiValue([]f64, self.allocator, self.input, &self.input_pos, self.default_EOL.value()) catch unreachable;
                self.input_pos += self.default_EOL.value().len;
                self.result.MEAN.append(value) catch unreachable;
            },
            State.EOF => {},
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
        const dimens = result.DIMENS;
        const genlab = result.*.GENLAB;
        const variab = result.*.VARIAB;
        const varunit = result.*.VARUNIT;
        const axislab = result.*.AXISLAB;
        const axiunit = result.*.AXIUNIT;
        const aximeth = result.*.AXIMETH;
        const min = result.*.MIN;
        const step = result.*.STEP;
        const nvars = result.*.NVARS;
        const uloads = result.*.ULOADS;
        const maxtime = result.*.MAXTIME;
        const mintime = result.*.MINTIME;
        const mean = result.*.MEAN;

        const template =
            \\ .FILE: {s}
            \\ .ACCESS: {s}
            \\ .FORM: {s}
            \\ .RECL: {s}
            \\ .FORMAT: {s}
            \\ .CONTENT: {s}
            \\ .CONFIG: {s}
            \\ .NDIMENS: {d}
            \\ .DIMENS: {any}
            \\ .GENLAB: {any}
            \\ .VARIAB: {any}
            \\ .VARUNIT: {any}
            \\ .AXISLAB: {any}
            \\ .AXIUNIT: {any}
            \\ .AXIMETH: {any}
            \\ .MIN: {any}
            \\ .STEP: {any}
            \\ .NVARS: {any}
            \\ .ULOADS: {any}
            \\ .MAXTIME: {any}
            \\ .MINTIME: {any}
            \\ .MEAN: {any}
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
            dimens,
            genlab,
            variab,
            varunit,
            axislab,
            axiunit,
            aximeth,
            min,
            step,
            nvars,
            uloads,
            maxtime,
            mintime,
            mean,
        });
        defer allocator.free(r);

        std.debug.print("\nRESULT:\n{s}\n\n", .{r});
    }
};

test "OK" {
    const allocator = std.testing.allocator;
    const specs = try std.fs.cwd().openFile("src/.data/startup.%41", .{ .mode = .read_only });
    defer specs.close();

    const contents = try specs.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(contents);
    // std.debug.print("file length: {d}\n", .{contents.len});

    var result: Result = try Result.init(allocator);
    defer result.deinit();

    var fsm = FSM.init();
    try Parser.parse(&fsm, contents, &result);

    // try Parser.printResult(allocator, &result);

    // const fileName = try result.FILE.toOwnedSlice();
    // defer allocator.free(fileName);

    // try std.testing.expectEqualStrings("startup.$41", fileName);
    try std.testing.expect(true);
}
