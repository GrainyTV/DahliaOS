#!/usr/bin/env scriptisto

// scriptisto-begin
// script_src: activeWorkspace.zig
// build_cmd: zig build-exe activeWorkspace.zig
// target_bin: activeWorkspace
// scriptisto-end

const std = @import("std");
const MS_TO_NS = 1_000_000;

const ShellCommand = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) ShellCommand {
        return .{ .allocator = allocator };
    }

    pub fn invoke(this: *const ShellCommand, shellCommand: []const []const u8) anyerror![]const u8 {
        const process = try std.process.Child.run(.{ .allocator = this.allocator, .argv = shellCommand });
        return std.mem.trimRight(u8, process.stdout, "\n");
    }
};

pub fn retrieveActiveWorkspace(allocator: std.mem.Allocator) anyerror![]const u8 {
    const shellHandler = ShellCommand.init(allocator);
    const activeWorkspace = try shellHandler.invoke(&.{ "hyprctl", "activeworkspace", "-j" });
    const parsedJson = try std.json.parseFromSlice(std.json.Value, allocator, activeWorkspace, .{});

    if (parsedJson.value.object.get("name")) |name| {
        return name.string;
    }

    unreachable;
}

pub fn main() anyerror!void {
    var ally = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer ally.deinit();
    const allocator = ally.allocator();

    var stdout = std.io.getStdOut();
    defer stdout.close();

    var activeWorkspace = try retrieveActiveWorkspace(allocator);

    while (true) {
        const latestActiveWorkspaceQuery = try retrieveActiveWorkspace(allocator);

        if (std.mem.eql(u8, activeWorkspace, latestActiveWorkspaceQuery) == false) {
            activeWorkspace = latestActiveWorkspaceQuery;
            try stdout.writer().print("{s}\n", .{activeWorkspace});
        }

        std.time.sleep(100 * MS_TO_NS);
    }
}
