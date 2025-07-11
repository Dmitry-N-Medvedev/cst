const std = @import("std");
// const addTests = @import("utils").addTests;

pub fn build(b: *std.Build) void {
    // specs
    const hdr_parser_specs = b.addSystemCommand(&.{ "zig", "build", "test" });
    hdr_parser_specs.cwd = b.path("src/hdr/");
    //
    // // bin
    const hdr_parser_bin = b.addSystemCommand(&.{ "zig", "build" });
    hdr_parser_bin.cwd = b.path("src/hdr/");
    b.getInstallStep().dependOn(&hdr_parser_specs.step);
    b.getInstallStep().dependOn(&hdr_parser_bin.step);
}
