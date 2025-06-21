const std = @import("std");

pub fn main() !void {}

fn parseHeaderFile() !void {}

test "parseHeaderFile" {
    const file = std.fs.cwd().openFile(".data/startup.%41", .{ .mode = .read_only });
    defer file.close();
}
