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
    }
}
