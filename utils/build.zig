const std = @import("std");

inline fn isTestableZigFile(entry: std.fs.Dir.Walker.Entry) bool {
    if (entry.kind != .file) {
        // std.debug.print("FALSE: entry.kind: {any}\n", .{entry.kind});

        return false;
    }

    if (std.mem.startsWith(u8, entry.path, ".zig-cache")) {
        return false;
    }

    if (std.mem.eql(u8, "build.zig", entry.path)) {
        return false;
    }

    if (std.mem.endsWith(u8, entry.path, ".zig")) {
        std.debug.print("TRUE: entry.path: {s}\n", .{entry.path});
        return true;
    }

    return false;
}

/// Adds tests for all *.zig files in src_dir (including subdirectories) to test_step.
pub fn addTests(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, test_step: *std.Build.Step, src_dir: []const u8) !void {
    var dir = try std.fs.cwd().openDir(src_dir, .{ .iterate = true });
    defer dir.close();

    var walker = try dir.walk(b.allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (isTestableZigFile(entry)) {
            //
            const test_artifact = b.addTest(.{
                .root_module = b.createModule(.{
                    .root_source_file = b.path(b.fmt("{s}/{s}", .{ src_dir, entry.path })),
                    .target = target,
                    .optimize = optimize,
                }),
            });
            // const run_test_artifact = b.addRunArtifact(test_artifact);
            test_step.dependOn(&test_artifact.step);
        }
    }
}
