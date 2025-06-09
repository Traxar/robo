const std = @import("std");

/// change working directory
pub fn cwd(sub_path: []const u8) !void {
    try std.fs.Dir.setAsCwd(try std.fs.cwd().openDir(sub_path, .{}));
}

/// change working directory
pub fn set_cwd(dir_path: []const u8) !void {
    try std.fs.Dir.setAsCwd(try std.fs.openDirAbsolute(dir_path, .{}));
}
