const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const hdr_parser_root_file = b.path("src/hdr_parser.zig");

    // hdr_parser
    const fsm = b.dependency("zigfsm", .{
        .target = target,
        .optimize = optimize,
    });
    const hdr_parser_mod = b.createModule(.{
        .root_source_file = hdr_parser_root_file,
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{
                .name = "zigfsm",
                .module = fsm.module("zigfsm"),
            },
        },
    });
    const hdr_parser = b.addExecutable(.{
        .name = "hdr",
        .root_module = hdr_parser_mod,
    });
    b.installArtifact(hdr_parser);

    const run_hdr_parser_run = b.addRunArtifact(hdr_parser);
    const run_hdr_client_step = b.step("run", "run hdr_parser");

    run_hdr_parser_run.step.dependOn(b.getInstallStep());

    const dir_arg = b.option([]const u8, "dir", "directory to process");
    if (dir_arg) |dir| {
        run_hdr_parser_run.addArgs(&[_][]const u8{dir});
    }
    run_hdr_client_step.dependOn(&run_hdr_parser_run.step);

    // DEBUG
    const composed_root_specs_file_name = try composeRootTestFileName(b.allocator, hdr_parser_root_file);
    try generateTestFile(b.allocator, composed_root_specs_file_name);

    const debug = b.addExecutable(.{
        .name = "debug",
        .root_module = hdr_parser_mod,
    });
    // const debugInstallPath = b.getInstallPath(.bin, "debug");
    const debugInstall = b.addInstallArtifact(debug, .{
        .dest_sub_path = "debug",
    });
    b.installArtifact(debug);
    const debugStep = b.step("debug", "produce debug executable");
    debugStep.dependOn(&debugInstall.step);
    b.default_step.dependOn(debugStep);
    // test

    const test_step = b.step("test", "run tests");
    const hdr_parser_test = b.addTest(.{
        .root_source_file = b.path(composed_root_specs_file_name),
        .target = target,
        .optimize = optimize,
    });
    hdr_parser_test.root_module.addImport("zigfsm", fsm.module("zigfsm"));

    const run_hdr_parser_test = b.addRunArtifact(hdr_parser_test);
    run_hdr_parser_test.step.name = "run";
    test_step.dependOn(&run_hdr_parser_test.step);
}

fn composeRootTestFileName(allocator: std.mem.Allocator, module_root_file: std.Build.LazyPath) ![]const u8 {
    const base_name = std.fs.path.basename(module_root_file.src_path.sub_path);
    const dot_idx = std.mem.lastIndexOf(u8, base_name, ".") orelse unreachable;
    const left = base_name[0..dot_idx];
    const right = base_name[(dot_idx + 1)..];
    const result = try std.fmt.allocPrint(allocator, ".{s}{s}{s}", .{
        left,
        ".specs.",
        right,
    });

    return result;
}

fn generateTestFile(allocator: std.mem.Allocator, out_path: []const u8) !void {
    var dir = try std.fs.cwd().openDir(".", .{ .iterate = true });
    defer dir.close();

    var walker: std.fs.Dir.Walker = try std.fs.Dir.walk(dir, allocator);
    defer walker.deinit();

    var imports = std.ArrayList([]const u8).init(allocator);
    defer imports.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind != .file) {
            continue;
        }

        if (std.mem.eql(u8, entry.path, "build.zig")) {
            continue;
        }

        if (std.mem.containsAtLeast(u8, entry.path, 1, ".specs.")) {
            continue;
        }

        if (std.mem.startsWith(u8, entry.path, ".zig-cache")) {
            continue;
        }

        if (std.mem.endsWith(u8, entry.path, ".zig")) {
            const entry_path = try allocator.dupe(u8, entry.path);
            try imports.append(entry_path);
        }
    }

    var file = try std.fs.cwd().createFile(out_path, .{ .truncate = true });
    defer file.close();

    const writer = file.writer();

    try writer.writeAll("test {\n");
    for (imports.items) |imported_file| {
        const line = try std.fmt.allocPrint(allocator, "\t_ = @import(\"{s}\");\n", .{imported_file});
        try writer.writeAll(line);
    }
    try writer.writeAll("}\n");
}
