const std = @import("std");
const AyArgparse = @import("ay-arg");
const LibGita = @import("libgita.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const stdout = std.io.getStdOut().writer();

    var args = try std.process.argsAlloc(allocator);
    defer allocator.free(args);

    const params = &[_]AyArgparse.ParamDesc{
        .{ .long = "no-name" },
        .{ .long = "no-tag" },
        .{ .long = "random" },
        .{ .long = "inlined" },
        .{ .long = "indent", .need_value = true },
        .{ .long = "sanskrit", .need_value = true },
        .{ .long = "english", .need_value = true },
        .{ .long = "notify" },
    };

    var argparse = AyArgparse.init(allocator, params[0..]);
    defer argparse.deinit();

    try argparse.parse(args[1..]);

    var option: LibGita.Options = .{};

    if (argparse.positionals.items.len < 1) {
        // TODO: usage
    }

    var chapter_id: ?[]const u8 = null;
    var verse_id: ?[]const u8 = null;

    if (argparse.positionals.items.len >= 1) {
        chapter_id = argparse.positionals.items[0];
    }

    if (argparse.positionals.items.len >= 2) {
        verse_id = argparse.positionals.items[1];
    }

    if (argparse.arguments.get("sanskrit")) |s| {
        if (std.mem.eql(u8, s, "false")) {
            option.sanskrit = false;
        }
    }

    if (argparse.arguments.get("english")) |s| {
        if (std.mem.eql(u8, s, "false")) {
            option.english = false;
        }
    }

    if (argparse.arguments.get("no-name") != null)
        option.no_name = true;

    if (argparse.arguments.get("no-tag") != null)
        option.no_tag = true;

    if (argparse.arguments.get("indent")) |indent|
        option.indent = try std.fmt.parseUnsigned(u8, indent, 10);

    if (argparse.arguments.get("inlined") != null)
        option.inlined = true;

    var gita = try LibGita.init(allocator, option);
    defer gita.deinit();

    var chapter: ?u8 = if (chapter_id) |cid| try std.fmt.parseUnsigned(u8, cid, 10) else null;
    var verse: ?u8 = if (verse_id) |vid| try std.fmt.parseUnsigned(u8, vid, 10) else null;

    if (argparse.arguments.get("random") != null) {
        var random_engine = std.rand.DefaultPrng.init(@intCast(u64, std.time.milliTimestamp()));
        const random = random_engine.random();

        if (chapter == null) {
            const num_chapter = gita.getChapterCount();
            chapter = random.uintLessThan(u8, @intCast(u8, num_chapter)) + 1;
        }

        if (verse != null) {
            // error: Conflicting arguments <verse> and --random
        }

        const num_verses = gita.getVerseCount(chapter.?);
        verse = random.uintLessThan(u8, @intCast(u8, num_verses)) + 1;
    }

    const notify_mode = argparse.arguments.get("notify") != null;
    var notifier = if (notify_mode) Notifier.init() else null;

    if (notify_mode) {
        var buf = std.ArrayList(u8).init(allocator);
        defer buf.deinit();

        try doPrint(&gita, buf.writer(), chapter.?, verse.?);
        try notifier.?.send(buf.items, 5000);
    } else {
        try doPrint(&gita, stdout, chapter.?, verse.?);
    }
}

fn doPrint(gita: *LibGita, writer: anytype, chapter_id: u8, verse_id: ?u8) !void {
    if (verse_id) |vid| {
        try gita.printVerse(writer, chapter_id, vid);
    } else {
        try gita.printChapter(writer, chapter_id);
    }
}

const Notifier = if (@import("builtin").os.tag == .windows) NotifierWindows else NotifierLinux;

const NotifierWindows = struct {
    pub fn init() NotifierWindows {
        return .{};
    }

    pub fn deinit(notifier: *NotifierWindows) void {
        _ = notifier;
    }

    pub fn send(notifier: *NotifierWindows, data: []const u8, timeout: i32) !void {
        _ = notifier;
        _ = data;
        _ = timeout;
    }
};

const NotifierLinux = struct {
    const libnotify = @cImport({
        @cInclude("libnotify/notify.h");
    });
    pub fn init() NotifierLinux {
        _ = libnotify.notify_init("Bhagavad Gita");
        return .{};
    }

    pub fn deinit(notifier: *NotifierLinux) void {
        _ = notifier;
    }

    pub fn send(notifier: *NotifierLinux, data: []const u8, timeout: i32) !void {
        _ = notifier;
        var n: ?*libnotify.NotifyNotification = null;

        n = libnotify.notify_notification_new("Bhagavad Gita", data.ptr, null);

        libnotify.notify_notification_set_timeout(n, timeout);
        if (libnotify.notify_notification_show(n, null) != 0) {
            //error
        }

        libnotify.g_object_unref(n);
    }
};
