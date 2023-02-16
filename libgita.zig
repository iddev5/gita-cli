const std = @import("std");
const source = @embedFile("gita.json");

const LibGita = @This();

pub const Options = struct {
    sanskrit: bool = true,
    english: bool = true,
};

allocator: std.mem.Allocator,
options: Options,
tree: std.json.ValueTree,

pub fn init(allocator: std.mem.Allocator, options: Options) !LibGita {
    var parser = std.json.Parser.init(allocator, false);
    defer parser.deinit();

    var tree = try parser.parse(source);
    errdefer tree.deinit();

    return .{
        .allocator = allocator,
        .options = options,
        .tree = tree,
    };
}

pub fn printVerse(lib: *LibGita, writer: anytype, chapter_id: usize, verse_id: usize) !void {
    var chapter_str: [2]u8 = [_]u8{' '} ** 2;
    var verse_str: [2]u8 = [_]u8{' '} ** 2;

    getChapterVerseString(chapter_id, &chapter_str, verse_id, &verse_str);

    const chapter = lib.tree.root.Object.get(std.mem.trimRight(u8, chapter_str[0..], " ")).?;
    const verse = chapter.Object.get(std.mem.trimRight(u8, verse_str[0..], " ")).?;

    try printVerseRaw(lib.options, verse, writer);
}

pub fn printChapter(lib: *LibGita, writer: anytype, chapter_id: usize) !void {
    var chapter_str: [2]u8 = [_]u8{' '} ** 2;

    getChapterVerseString(chapter_id, &chapter_str, null, null);

    const chapter = lib.tree.root.Object.get(std.mem.trimRight(u8, chapter_str[0..], " ")).?;
    const num_verses = chapter.Object.count();

    var i: usize = 1;
    while (i < num_verses + 1) : (i += 1) {
        var verse_str: [2]u8 = [_]u8{' '} ** 2;
        getChapterVerseString(null, null, i, &verse_str);

        const verse = chapter.Object.get(std.mem.trimRight(u8, verse_str[0..], " ")).?;
        try printVerseRaw(lib.options, verse, writer);

        if (i != num_verses)
            try writer.writeAll("\n\n\n\n");
    }
}

fn printVerseRaw(option: LibGita.Options, verse: std.json.Value, stdout: anytype) !void {
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

fn getChapterVerseString(chapter: ?usize, chapter_str: ?[]u8, verse: ?usize, verse_str: ?[]u8) void {
    if (chapter) |c| {
        _ = std.fmt.formatIntBuf(chapter_str.?, c, 10, .lower, .{});
    }

    if (verse) |v| {
        _ = std.fmt.formatIntBuf(verse_str.?, v, 10, .lower, .{});
    }
}
