const std = @import("std");
const Parser = @import("Parser.zig").Parser;
const Result = @import("Parser.zig").Result;
const FSM = @import("Parser.zig").FSM;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var data_root_path: []const u8 = undefined;

    var i: usize = 1;

    while (i < args.len) {
        if (std.mem.eql(u8, args[i], "--dir") and i + 1 < args.len) {
            data_root_path = args[i + 1];
            i += 2;
        } else {
            i += 1;
        }
    }

    if (data_root_path.len == 0) {
        std.debug.print("Usage: {s} --dir <directory>\n", .{args[0]});
        return;
    }

    const max_file_size = 1 * 1024 * 1024;
    var data_root_dir = try std.fs.cwd().openDir(data_root_path, .{ .iterate = true });
    defer data_root_dir.close();

    var walker = try data_root_dir.walk(allocator);
    defer walker.deinit();

    const root_path = try std.fs.cwd().realpathAlloc(allocator, data_root_path);
    defer allocator.free(root_path);

    var file_paths = std.ArrayList([]const u8).init(allocator);
    defer {
        for (file_paths.items) |path| {
            allocator.free(path);
        }

        file_paths.deinit();
    }

    var file_full_path: []const u8 = undefined;
    while (try walker.next()) |entry| {
        if (entry.kind != .file) {
            unreachable;
        }

        file_full_path = try std.fs.path.join(allocator, &[_][]const u8{ root_path, entry.path });
        try file_paths.append(file_full_path);
    }

    for (file_paths.items) |hdr_file_full_path| {
        const hdr_file = try std.fs.cwd().openFile(hdr_file_full_path, .{ .mode = .read_only });
        defer hdr_file.close();

        const hdr_contents = try hdr_file.readToEndAlloc(allocator, max_file_size);
        defer allocator.free(hdr_contents);

        var result: Result = try Result.init(allocator);
        defer result.deinit();

        var fsm = FSM.init();
        try Parser.parse(&fsm, hdr_contents, &result);

        // printResult(result, hdr_file_full_path);
    }
}

// fn printResult(result: Result, hdr_file_full_path: []const u8) void {
//     std.debug.print("\n{s}\n", .{hdr_file_full_path});
//
//     std.debug.print("\tFILE:\t{s}\n", .{result.FILE.items});
//     std.debug.print("\tACCESS:\t{s}\n", .{@tagName(result.ACCESS)});
//     std.debug.print("\tFORM:\t{s}\n", .{@tagName(result.FORM)});
//     std.debug.print("\tRECL:\t{d}\n", .{result.RECL.?});
//     std.debug.print("\tFORMAT:\t{s}\n", .{result.FORMAT});
//     std.debug.print("\tCONTENT:\t{s}\n", .{result.CONTENT});
//     std.debug.print("\tCONFIG:\t{s}\n", .{result.CONFIG});
//     std.debug.print("\tNDIMENS:\t{d}\n", .{result.NDIMENS});
//     std.debug.print("\tDIMENS:\t{any}\n", .{result.DIMENS});
//     std.debug.print("\tGENLAB:\t{s}\n", .{result.GENLAB});
//
//     std.debug.print("\tVARIAB:\t ", .{});
//     for (result.VARIAB) |variab| {
//         std.debug.print("{s} ", .{variab});
//     }
//
//     std.debug.print("\tVARUNIT:\t ", .{});
//     for (result.VARUNIT) |varunit| {
//         std.debug.print("{s} ", .{@tagName(varunit)});
//     }
//
//     std.debug.print("\n", .{});
// }
