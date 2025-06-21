const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // hrd
    const hdr_mod = b.createModule(.{
        .root_source_file = b.path("hdr.zig"),
        .target = target,
        .optimize = optimize,
    });
    const hdr = b.addExecutable(.{
        .name = "hrd",
        .root_module = hdr_mod,
    });
    const run_hdr_cmd = b.addRunArtifact(hdr);
    run_hdr_cmd.setCwd(.{
        .cwd_relative = b.pathJoin(&.{
            b.install_prefix,
            "bin",
        }),
    });
    const run_hdr_step = b.step("run", "run hdr");
    run_hdr_step.dependOn(&run_hdr_cmd.step);

    if (b.args) |args| {
        run_hdr_cmd.addArgs(args);
    }
    run_hdr_cmd.step.dependOn(b.getInstallStep());
    b.installArtifact(hdr);

    // hdr_parser
    const hdr_parser_mod = b.createModule(.{
        .root_source_file = b.path("hdr_parser.zig"),
        .target = target,
        .optimize = optimize,
    });
    const hdr_parser = b.addExecutable(.{
        .name = "hdr_parser",
        .root_module = hdr_parser_mod,
    });
    const run_hdr_parser_cmd = b.addRunArtifact(hdr_parser);
    run_hdr_parser_cmd.setCwd(.{
        .cwd_relative = b.pathJoin(&.{
            b.install_prefix,
            "bin",
        }),
    });
    const run_hdr_client_step = b.step("run_parser", "run hdr_parser");
    run_hdr_client_step.dependOn(&run_hdr_parser_cmd.step);

    if (b.args) |args| {
        run_hdr_parser_cmd.addArgs(args);
    }

    run_hdr_parser_cmd.step.dependOn(b.getInstallStep());
    b.installArtifact(hdr_parser);

    // test
    const test_step = b.step("test", "run tests");
    var test_dir = try std.fs.cwd().openDir("./", .{ .iterate = true });
    defer test_dir.close();

    var iter = test_dir.iterate();

    while (try iter.next()) |entry| {
        const is_zig_file = std.mem.eql(u8, entry.name, ".zig");
        if (is_zig_file == false) continue;

        const test_artifact = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(entry.name),
                .target = target,
                .optimize = optimize,
            }),
        });
        const run_test = b.addRunArtifact(test_artifact);
        run_test.step.name = b.fmt("test {s}\n", .{
            std.fs.path.basename(entry.name),
        });
        test_step.dependOn(&run_test.step);
    }
}
