#!/usr/bin/env scriptisto

// scriptisto-begin
// script_src: openWorkspaces.zig
// build_cmd: zig build-exe openWorkspaces.zig
// target_bin: openWorkspaces
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

pub fn retrieveOpenWorkspaces(allocator: std.mem.Allocator) anyerror![][]const u8 {
    const shellHandler = ShellCommand.init(allocator);
    const openWorkspaces = try shellHandler.invoke(&.{ "hyprctl", "workspaces", "-j" });
    const parsedJson = try std.json.parseFromSlice(std.json.Value, allocator, openWorkspaces, .{});
    var workspaceList = std.ArrayList([]const u8).init(allocator);

    for (parsedJson.value.array.items) |workspace| {
        if (workspace.object.get("name")) |name| {
            try workspaceList.append(name.string);
            continue;
        }
     
        unreachable;
    }

    return workspaceList.toOwnedSlice();
}

pub fn compareArrayOfStrings(arr1: *const [][]const u8, arr2: *const [][]const u8) bool {
    if (arr1.len != arr2.len) {
        return false;
    }

    for (arr1.*, arr2.*) |s1, s2| {
        if (std.mem.eql(u8, s1, s2) == false) {
            return false;
        }
    }

    return true;
}

pub fn main() anyerror!void {
    var ally = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer ally.deinit();
    const allocator = ally.allocator();

    var stdout = std.io.getStdOut();
    defer stdout.close();

    var openWorkspaces = try retrieveOpenWorkspaces(allocator);

    while (true) {
        const latestOpenWorkspaceQuery = try retrieveOpenWorkspaces(allocator);

        if (compareArrayOfStrings(&openWorkspaces, &latestOpenWorkspaceQuery) == false) {
            openWorkspaces = latestOpenWorkspaceQuery;
            try std.json.stringify(openWorkspaces, .{}, stdout.writer());
            try stdout.writer().writeAll("\n");
        }

        std.time.sleep(100 * MS_TO_NS);
    }
}
