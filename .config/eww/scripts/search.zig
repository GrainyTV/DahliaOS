#!/usr/bin/env scriptisto

// scriptisto-begin
// script_src: search.zig
// build_cmd: zig build-exe search.zig
// target_bin: search
// scriptisto-end

const std = @import("std");
const Entry = std.fs.Dir.Entry;
const RunResult = std.ChildProcess.RunResult;
const IconThemeType = enum {
    default,
    fallback,
};
const IconTheme = struct {
    path: []const u8,
    type: IconThemeType,
};
const IconDetails = struct {
    file: []const u8,
    hasPadding: bool,
};
const IconHandler = struct {
    allocator: std.mem.Allocator,
    themes: [2]IconTheme,

    fn exists(_: *const IconHandler, entry: *const []const u8) anyerror!bool {
        var file = std.fs.openFileAbsolute(entry.*, .{}) catch |exception| {
            switch (exception) {
                error.FileNotFound => return false,
                else => return exception,
            }
        };
        defer file.close();

        return true;
    }

    pub fn init(allocator: std.mem.Allocator) anyerror!IconHandler {
        const iconThemeRequest = try std.ChildProcess.run(.{
            .allocator = allocator,
            .argv = &.{ "gsettings", "get", "org.gnome.desktop.interface", "icon-theme" },
        });
        const homeEnvVar = try std.process.getEnvVarOwned(allocator, "HOME");
        const iconTheme = std.mem.trim(u8, iconThemeRequest.stdout, "\n'");

        return .{
            .allocator = allocator,
            .themes = [_]IconTheme{
                .{
                    .path = try std.fmt.allocPrint(allocator, "{s}/.local/share/icons/{s}", .{ homeEnvVar, iconTheme }),
                    .type = .default,
                },
                .{
                    .path = "/usr/share/icons/hicolor",
                    .type = .fallback,
                },
            },
        };
    }

    pub fn loadAppropriateIcon(self: *const IconHandler, name: *const []const u8) anyerror!?IconDetails {
        const svg = try std.fmt.allocPrint(self.allocator, "{s}.svg", .{name.*});
        const png = try std.fmt.allocPrint(self.allocator, "{s}.png", .{name.*});
        const contexts = [_][]const u8{ "apps", "devices", "mimetypes", "places" };
        const sizes = [_][]const u8{ "scalable", "512x512", "256x256", "128x128", "64x64", "48x48", "32x32" };

        for (self.themes) |theme| {
            for (contexts) |context| {
                switch (theme.type) {
                    .default => {
                        const entry = try std.fs.path.join(self.allocator, &.{ theme.path, sizes[0], context, svg });

                        if (try self.exists(&entry)) {
                            return .{
                                .file = entry,
                                .hasPadding = true,
                            };
                        }
                    },
                    .fallback => {
                        for (sizes) |size| {
                            const extension = if (std.mem.eql(u8, size, "scalable")) svg else png;
                            const entry = try std.fs.path.join(self.allocator, &.{ theme.path, size, context, extension });

                            if (try self.exists(&entry)) {
                                return .{
                                    .file = entry,
                                    .hasPadding = false,
                                };
                            }
                        }
                    },
                }
            }
        }

        return null;
    }
};
const SearchResult = struct {
    title: []const u8,
    description: []const u8,
    icon: []const u8,
    exec: []const u8,
    padded: bool,
};

pub fn isDesktopFile(entry: *const Entry) bool {
    return entry.kind == .file and std.mem.eql(u8, std.fs.path.extension(entry.name), ".desktop");
}

pub fn loadProperty(allocator: std.mem.Allocator, comptime property: []const u8, content: *const []const u8) anyerror!?[]const u8 {

    // ========================================== //
    // P = Perl Type Regex                        //
    // o = Only Return Non-Empty Parts of Matches //
    // m = Number of Matches Needed (1)           //
    // ========================================== //

    const regex = try std.fmt.allocPrint(allocator, "(?<=^{s}=).+", .{property});
    var propertyRequest = std.ChildProcess.init(&.{ "grep", "-P", "-o", "-m1", regex }, allocator);
    propertyRequest.stdin_behavior = .Pipe;
    propertyRequest.stdout_behavior = .Pipe;
    propertyRequest.stderr_behavior = .Pipe;

    var stdout = std.ArrayList(u8).init(allocator);
    var stderr = std.ArrayList(u8).init(allocator);
    try propertyRequest.spawn();

    if (propertyRequest.stdin) |inputPipe| {
        defer {
            inputPipe.close();
            propertyRequest.stdin = null;
        }
        try inputPipe.writer().writeAll(content.*);
    }

    try propertyRequest.collectOutput(&stdout, &stderr, std.math.maxInt(usize));

    const propertyResult = RunResult{
        .term = try propertyRequest.wait(),
        .stdout = try stdout.toOwnedSlice(),
        .stderr = try stderr.toOwnedSlice(),
    };

    return if (propertyResult.term.Exited == 1) null else std.mem.trimRight(u8, propertyResult.stdout, "\n");
}

pub fn stringToBool(value: *const []const u8) bool {
    const isTrue = std.mem.eql(u8, value.*, "true");
    const isFalse = std.mem.eql(u8, value.*, "false");
    std.debug.assert(isTrue or isFalse);
    return if (isTrue) true else false;
}

pub fn matchesNameFilter(allocator: std.mem.Allocator, query: *const []const u8, name: *const []const u8) anyerror!bool {
    return if (std.mem.eql(u8, query.*, "*")) true else {
        const lowerCaseQuery = try std.ascii.allocLowerString(allocator, query.*);
        const lowerCaseName = try std.ascii.allocLowerString(allocator, name.*);
        return std.mem.containsAtLeast(u8, lowerCaseName, 1, lowerCaseQuery);
    };
}

pub fn compareByName(_: void, lhs: SearchResult, rhs: SearchResult) bool {
    const comparer = std.ascii.orderIgnoreCase(lhs.title, rhs.title);

    return switch (comparer) {
        .lt => true,
        .eq => false,
        .gt => false,
    };
}

pub fn main() anyerror!void {
    const invocationTime: i128 = std.time.nanoTimestamp();

    var ally = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer ally.deinit();
    const allocator = ally.allocator();

    _ = try std.ChildProcess.run(.{
        .allocator = allocator,
        .argv = &.{ "eww", "update", try std.fmt.allocPrint(allocator, "debounceTime={d}", .{invocationTime}) },
    });
    
    std.time.sleep(175 * std.time.ns_per_ms);

    const debounceProcess = try std.ChildProcess.run(.{ .allocator = allocator, .argv = &.{ "eww", "get", "debounceTime" } });
    const latestInvocation = try std.fmt.parseInt(i128, std.mem.trimRight(u8, debounceProcess.stdout, "\n"), 10);

    if (latestInvocation != invocationTime) {
        return;
    }

    var cliArguments = try std.process.argsWithAllocator(allocator);
    _ = cliArguments.skip();

    const args = cliArguments.next();
    const searchQuery = if (args == null or args.?.len == 0) "*" else args.?;

    var appDir = try std.fs.openDirAbsolute("/usr/share/applications", .{
        .access_sub_paths = false,
        .iterate = true,
        .no_follow = true,
    });
    defer appDir.close();
    var iterator = appDir.iterate();

    var foundEntries = std.ArrayList(SearchResult).init(allocator);
    const iconHandler = try IconHandler.init(allocator);

    while (try iterator.next()) |app| {
        if (isDesktopFile(&app)) {
            const content = try appDir.readFileAlloc(allocator, app.name, std.math.maxInt(usize));
            const hasNoDisplay = try loadProperty(allocator, "NoDisplay", &content);
            const hasNotShowIn = try loadProperty(allocator, "NotShowIn", &content);

            if ((hasNoDisplay != null and stringToBool(&hasNoDisplay.?) == true) or hasNotShowIn != null) {
                continue;
            }

            const name = try loadProperty(allocator, "Name", &content) orelse continue;

            if (try matchesNameFilter(allocator, &searchQuery, &name) == false) {
                continue;
            }

            const iconId = try loadProperty(allocator, "Icon", &content) orelse continue;

            if (try iconHandler.loadAppropriateIcon(&iconId)) |icon| {
                const desc = try loadProperty(allocator, "GenericName", &content) orelse
                    try loadProperty(allocator, "Comment", &content) orelse
                    try allocator.dupe(u8, "...");
                const exec = try allocator.dupe(u8, app.name);

                try foundEntries.append(.{
                    .title = name,
                    .description = desc,
                    .icon = icon.file,
                    .exec = exec,
                    .padded = icon.hasPadding,
                });
            }
        }
    }

    const finalEntries = try foundEntries.toOwnedSlice();
    std.sort.insertion(SearchResult, finalEntries, {}, compareByName);

    const jsonResult = try std.json.stringifyAlloc(allocator, finalEntries, .{});
    const variable = try std.fmt.allocPrint(allocator, "applications={s}", .{jsonResult});
    _ = try std.ChildProcess.run(.{ .allocator = allocator, .argv = &.{ "eww", "update", variable } });
}
