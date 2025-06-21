const std = @import("std");

pub fn build(b: *std.Build) void {
    const build_all = b.step("all", "build all");
    const test_all = b.step("test", "test all");

    var src_dir = std.fs.cwd().openDir("src/", .{ .iterate = true }) catch |err| {
        std.debug.print("failed to open src directory: {}\n", .{err});

        return;
    };
    defer src_dir.close();

    var iter = src_dir.iterate();

    while (iter.next() catch |err| {
        std.debug.print("cannot iterate src directory: {}\n", .{err});
        return;
    }) |entry| {
        if (entry.kind != .directory) continue;

        const subproject_path = std.fs.path.join(b.allocator, &[_][]const u8{
            "src",
            entry.name,
            "build.zig",
        }) catch continue;
        defer b.allocator.free(subproject_path);

        const subproject_build = b.addSystemCommand(&[_][]const u8{
            "zig",
            "build",
            "--build-file",
            subproject_path,
        });
        const subproject_test = b.addSystemCommand(&[_][]const u8{
            "zig",
            "build",
            "--build-file",
            subproject_path,
            "test",
        });

        build_all.dependOn(&subproject_build.step);
        test_all.dependOn(&subproject_test.step);

        std.debug.print("added build & test steps for {s}\n", .{entry.name});
    }

    b.default_step = build_all;
}
