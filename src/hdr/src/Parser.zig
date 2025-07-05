const std = @import("std");
const zigfsm = @import("zigfsm");
// const Token = @import("domain/Token.zig").Token;
// const TokenAccessValue = @import("domain/Token.zig").TokenAccessValue;
// const TokenFormValue = @import("domain/Token.zig").TokenFormValue;
// const TokenVarUnitValue = @import("domain/Token.zig").TokenVarUnitValue;
// const TokenAxiUnitValue = @import("domain/Token.zig").TokenAxiUnitValue;

// const State = enum {
//     PARSING_KEY,
//     PARSING_VALUE,
//     EOF,
// };
//
// const Event = enum {
//     SIG_KEY,
//     SIG_VALUE,
//     SIG_EOF,
// };
//
// const transition_table = [_]zigfsm.Transition(State, Event){
//     .{ .event = .SIG_KEY, .from = .PARSING_KEY, .to = .PARSING_VALUE },
//     .{ .event = .SIG_VALUE, .from = .PARSING_VALUE, .to = .PARSING_KEY },
//     .{ .event = .SIG_EOF, .from = .PARSING_VALUE, .to = .EOF },
// };
//
// const Result = struct {
//     FILE: []const u8 = undefined,
//     ACCESS: TokenAccessValue = undefined,
//     FORM: TokenFormValue = undefined,
//     RECL: u8 = undefined,
//     // FORMAT: type = undefined,
//     CONTENT: []const u8 = undefined,
//     CONFIG: []const u8 = undefined,
//     NDIMENS: []u8 = undefined,
//     DIMENS: []u16 = undefined,
//     GENLAB: []const u8 = undefined,
//     VARIAB: []const u8 = undefined,
//     VARUNIT: []const TokenVarUnitValue = undefined,
//     AXISLAB: []const []const u8 = undefined,
//     AXIUNIT: []const []const TokenAxiUnitValue = undefined,
//     AXIMETH: []const []const u8 = undefined,
//     MIN: f64 = undefined,
//     STEP: f64 = undefined,
//     NVARS: u8,
//     ULOADS: []const []const f64 = undefined,
//     MAXTIME: []const []const f64 = undefined,
//     MINTIME: []const []const f64 = undefined,
//     MEAN: []const []const f64 = undefined,
// };
//
// var FSM = zigfsm.StateMachineFromTable(State, Event, &transition_table, State.PARSING_KEY, &[_]State{State.EOF}).init();
//
// const Parser = struct {
//     handler: FSM.Handler,
//     fsm: *FSM,
//     input: []const u8,
//     input_idx: usize,
//
//     pub fn parse(fsm: *FSM, input: []const u8, result: *Result) !void {
//         var instance: @This() = .{
//             .handler = zigfsm.Interface.make(FSM.Handler, @This()),
//             .fsm = fsm,
//             .input = input,
//             .input_idx = 0,
//         };
//
//         instance.fsm.setTransitionHandlers(&.{&instance.handler});
//
//         try instance.execute(result);
//     }
//
//     fn execute(result: *Result) !void {
//         _ = result;
//     }
//
//     pub fn onTransition(handler: *FSM.Handler, event: ?Event, from: State, to: State) zigfsm.HandlerResult {
//         const self = zigfsm.Interface.downcast(@This(), handler);
//
//         std.debug.print("self: {any}\n", .{self});
//         std.debug.print("event: {any}\n", .{event});
//         std.debug.print("from: {any}\n", .{from});
//         std.debug.print("to: {any}\n", .{to});
//
//         return zigfsm.HandlerResult.Continue;
//     }
// };

test "minimal with event defined using a table" {
    const S = enum { on, off };
    const E = enum { click };
    const definition = [_]zigfsm.Transition(S, E){
        .{ .event = .click, .from = .on, .to = .off },
        .{ .event = .click, .from = .off, .to = .on },
    };
    var fsm = zigfsm.StateMachineFromTable(S, E, &definition, .off, &.{}).init();

    // Transition manually
    try fsm.transitionTo(.on);
    try std.testing.expectEqual(fsm.currentState(), .on);

    // Transition through an event
    _ = try fsm.do(.click);
    try std.testing.expectEqual(fsm.currentState(), .off);
}

// test "OK" {
//     std.debug.print("FSM: {any}\n", .{FSM});
//     // const input: []const u8 = "FILE\t startup.$389";
//     // const result: Result = undefined;
//     // std.debug.print("input: {s}\n", .{input});
//     // std.debug.print("result: {any}\n", .{result});
//
//     // try Parser.parse(&FSM, input, &result);
//     // try std.testing.expect(true);
// }
