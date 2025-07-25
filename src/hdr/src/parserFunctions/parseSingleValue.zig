const std = @import("std");
const Whitespace = @import("WhiteSpace.zig").Whitespace;
const TokenAxiUnitValue = @import("../domain/Token.zig").TokenAxiUnitValue;

pub fn parseSingleValue(comptime T: type, input: []const u8, pos: *usize, stop: []const u8) !T {
    const stop_pos_rel = std.mem.indexOf(u8, input[pos.*..], stop) orelse unreachable;
    const stop_pos_abs = pos.* + stop_pos_rel;
    defer {
        pos.* = stop_pos_abs;
    }
    const data = input[pos.*..stop_pos_abs];
    const trimmed = std.mem.trim(u8, data, Whitespace);

    return switch (T) {
        []const u8 => trimmed,
        u8 => std.fmt.parseInt(u8, trimmed, 10),
        f64 => std.fmt.parseFloat(f64, trimmed),
        TokenAxiUnitValue => std.meta.stringToEnum(TokenAxiUnitValue, trimmed) orelse unreachable,
        else => @compileError("unsupported type" ++ @typeName(T)),
    };
}

test "single line" {
    const allocator = std.testing.allocator;

    const Token = @import("../domain/Token.zig").Token;
    const EOL = @import("EOL.zig").EOL;
    const Parser = @import("../Parser.zig").Parser;

    const file_name = "powprod.$24";
    const line = try std.fmt.allocPrint(allocator, "{s}\t{s}{s}", .{ @tagName(Token.FILE), file_name, EOL.RN.value() });
    defer allocator.free(line);

    var pos: usize = 0;
    const key = Parser.resolveKey(line, &pos) orelse unreachable;
    const value = parseSingleValue([]const u8, line, &pos, EOL.RN.value()) catch unreachable;

    try std.testing.expectEqual(Token.FILE, key);
    try std.testing.expectEqualSlices(u8, file_name, value);
    try std.testing.expectEqual(line.len, pos + EOL.RN.value().len);
}

fn shouldRunTest() bool {
    return std.process.hasEnvVar(std.testing.allocator, "RUN_SKIPPED_TESTS") catch return false;
}

test "OK" {
    const allocator = std.testing.allocator;

    if (!shouldRunTest()) {
        std.debug.print("skipped\n", .{});
        return;
    }

    const Token = @import("../domain/Token.zig").Token;
    const EOL = @import("EOL.zig").EOL;
    const Parser = @import("../Parser.zig").Parser;

    const TokenSize = std.AutoHashMap(Token, usize);
    var tokenSizeMap = TokenSize.init(allocator);
    defer tokenSizeMap.deinit();

    try tokenSizeMap.put(Token.FILE, 21);
    try tokenSizeMap.put(Token.ACCESS, 11);
    try tokenSizeMap.put(Token.FORM, 11);
    try tokenSizeMap.put(Token.RECL, 20);
    try tokenSizeMap.put(Token.FORMAT, 13);
    try tokenSizeMap.put(Token.CONTENT, 17);
    try tokenSizeMap.put(Token.CONFIG, 19);
    try tokenSizeMap.put(Token.NDIMENS, 10);
    try tokenSizeMap.put(Token.DIMENS, 32);
    try tokenSizeMap.put(Token.GENLAB, 46);
    try tokenSizeMap.put(Token.VARIAB, 5464);
    try tokenSizeMap.put(Token.VARUNIT, 445);
    try tokenSizeMap.put(Token.AXISLAB, 32);
    try tokenSizeMap.put(Token.AXIUNIT, 10);
    try tokenSizeMap.put(Token.AXIMETH, 10);
    try tokenSizeMap.put(Token.AXIVAL, 752);
    try tokenSizeMap.put(Token.MIN, 18);
    try tokenSizeMap.put(Token.STEP, 23);
    try tokenSizeMap.put(Token.NVARS, 10);
    try tokenSizeMap.put(Token.MAXTIME, 1940);
    try tokenSizeMap.put(Token.MINTIME, 1940);
    try tokenSizeMap.put(Token.MEAN, 2049);

    var single_value_tokens = std.ArrayList(Token).init(allocator);
    defer single_value_tokens.deinit();

    var iter = tokenSizeMap.keyIterator();
    var i: usize = 0;
    while (iter.next()) |token| : (i += 1) {
        single_value_tokens.append(token.*) catch unreachable;
    }

    const aggregated_path = "src/specs/aggregated";
    var aggregated_dir = try std.fs.cwd().openDir(aggregated_path, .{});
    defer aggregated_dir.close();

    var token_name: []const u8 = undefined;
    var token_file_name: []const u8 = undefined;
    var b: u8 = undefined;

    for (single_value_tokens.items) |token| {
        token_name = @tagName(token);
        std.debug.print("=== {s} ===\n", .{token_name});
        token_file_name = try std.fmt.allocPrint(allocator, "{s}.txt", .{token_name});
        defer allocator.free(token_file_name);

        const token_file = try aggregated_dir.openFile(token_file_name, .{ .mode = .read_only });
        defer token_file.close();

        var buffered_reader = std.io.bufferedReader(token_file.reader());
        const reader = buffered_reader.reader();

        // const line_max_size = tokenSizeMap.get(token) orelse unreachable;
        var line: []const u8 = undefined;
        var pos: usize = 0;

        var slice: []const u8 = undefined;
        var line_number: usize = 0;
        while (true) : ({
            pos = 0;
            line_number += 1;
        }) {
            var buffer = std.ArrayList(u8).init(allocator);
            defer buffer.deinit();

            reader.streamUntilDelimiter(buffer.writer(), EOL.R.value()[0], null) catch |err| switch (err) {
                error.EndOfStream => {
                    break;
                },
                else => {
                    std.debug.print("ERR: @{d} {any}\n", .{ line_number, err });

                    return err;
                },
            };
            line = try buffer.toOwnedSlice();
            defer allocator.free(line);

            slice = try std.fmt.allocPrint(allocator, "{s}{s}", .{ line, EOL.RN.value() });
            defer allocator.free(slice);

            const key = Parser.resolveKey(slice, &pos);
            try std.testing.expectEqualSlices(u8, token_name, @tagName(key.?));
            _ = try parseSingleValue([]const u8, slice, &pos, EOL.N.value());

            b = reader.readByte() catch |err| switch (err) {
                error.EndOfStream => {
                    break;
                },
                else => return err,
            };
        }
    }
}
