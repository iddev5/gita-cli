const std = @import("std");
const AyArgparse = @import("ay-arg");
const source = @embedFile("gita.json");

const Options = struct {
    sanskrit: bool = true,
    english: bool = true,
    full_chapter: bool = true,
    chapter_id: []const u8 = undefined,
    verse_id: ?[]const u8 = null,
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var args = try std.process.argsAlloc(allocator);
    defer allocator.free(args);

    const params = &[_]AyArgparse.ParamDesc{
        .{ .long = "sanskrit", .need_value = true },
        .{ .long = "english", .need_value = true },
    };

    var argparse = AyArgparse.init(allocator, params[0..]);
    defer argparse.deinit();

    try argparse.parse(args[1..]);

    var option: Options = .{};

    if (argparse.positionals.items.len < 1) {
        // TODO: usage
    }

    option.chapter_id = argparse.positionals.items[0];

    if (argparse.positionals.items.len < 2) {
        option.full_chapter = true;
    } else {
        option.verse_id = argparse.positionals.items[1];
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

    var parser = std.json.Parser.init(allocator, false);
    defer parser.deinit();

    var tree = try parser.parse(source);
    defer tree.deinit();

    const chapter = tree.root.Object.get(option.chapter_id).?;

    if (option.verse_id) |verse_id| {
        const verse = chapter.Object.get(verse_id).?;
        try printVerse(option, verse, stdout);
    } else {
        var i: usize = 1;
        const num_verses = chapter.Object.count();
        while (i < num_verses + 1) : (i += 1) {
            const verse_id = try std.fmt.allocPrint(allocator, "{}", .{i});
            defer allocator.free(verse_id);

            const verse = chapter.Object.get(verse_id).?;
            try printVerse(option, verse, stdout);

            if (i != num_verses)
                try stdout.writeAll("\n\n\n\n");
        }
    }

    try bw.flush();
}

fn printVerse(option: Options, verse: std.json.Value, stdout: anytype) !void {
    if (option.sanskrit) {
        try stdout.print("{s}\n", .{
            verse.Object.get("sanskrit").?.String,
        });
    }

    if (option.english) {
        try stdout.print("{s}\n", .{
            verse.Object.get("english").?.String,
        });
    }
}
