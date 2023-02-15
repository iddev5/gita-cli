const std = @import("std");
const AyArgparse = @import("ay-arg");
const source = @embedFile("gita.json");

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
    const chapter_id = argparse.positionals.items[0];
    const verse_id = argparse.positionals.items[1];

    var parser = std.json.Parser.init(allocator, false);
    defer parser.deinit();

    var tree = try parser.parse(source);
    defer tree.deinit();

    const chapter = tree.root.Object.get(chapter_id).?;
    const verse = chapter.Object.get(verse_id).?;

    var option: struct {
        sanskrit: bool = true,
        english: bool = true,
    } = .{};

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

    try bw.flush();
}
