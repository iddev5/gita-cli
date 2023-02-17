const std = @import("std");
const AyArgparse = @import("ay-arg");
const LibGita = @import("libgita.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var args = try std.process.argsAlloc(allocator);
    defer allocator.free(args);

    const params = &[_]AyArgparse.ParamDesc{
        .{ .long = "no-name" },
        .{ .long = "no-tag" },
        .{ .long = "indent", .need_value = true },
        .{ .long = "sanskrit", .need_value = true },
        .{ .long = "english", .need_value = true },
    };

    var argparse = AyArgparse.init(allocator, params[0..]);
    defer argparse.deinit();

    try argparse.parse(args[1..]);

    var option: LibGita.Options = .{};

    if (argparse.positionals.items.len < 1) {
        // TODO: usage
    }

    var chapter_id: []const u8 = undefined;
    var verse_id: ?[]const u8 = null;

    chapter_id = argparse.positionals.items[0];

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

    var gita = try LibGita.init(allocator, option);
    defer gita.deinit();

    if (verse_id) |vid| {
        try gita.printVerse(
            stdout,
            try std.fmt.parseUnsigned(u8, chapter_id, 10),
            try std.fmt.parseUnsigned(u8, vid, 10),
        );
    } else {
        try gita.printChapter(stdout, try std.fmt.parseUnsigned(u8, chapter_id, 10));
    }

    try bw.flush();
}
