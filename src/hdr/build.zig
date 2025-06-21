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
}
