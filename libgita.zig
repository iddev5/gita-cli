const std = @import("std");
const source = @embedFile("gita.json");

const LibGita = @This();

pub const Options = struct {
    sanskrit: bool = true,
    english: bool = true,
    no_name: bool = false,
    no_tag: bool = false,
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
    const chapter = lib.tree.root.Array.items[chapter_id - 1];
    const verse = chapter.Array.items[verse_id - 1];

    try printVerseRaw(lib.options, verse, writer);
}

pub fn printChapter(lib: *LibGita, writer: anytype, chapter_id: usize) !void {
    const chapter = lib.tree.root.Array.items[chapter_id - 1];
    const num_verses = chapter.Array.items.len;

    var i: usize = 1;
    while (i < num_verses + 1) : (i += 1) {
        const verse = chapter.Array.items[i - 1];
        try printVerseRaw(lib.options, verse, writer);

        if (i != num_verses)
            try writer.writeAll("\n\n\n\n");
    }
}

fn printVerseRaw(option: LibGita.Options, verse: std.json.Value, stdout: anytype) !void {
    if (!option.no_name) {
        try stdout.writeAll("Bhagavad Gita: ");
    }

    if (!option.no_tag) {
        try stdout.print("{}.{}", .{ 1, 1 });
    }

    if (@boolToInt(option.no_name) & @boolToInt(option.no_tag) == 0)
        try stdout.writeAll("\n\n");

    if (option.sanskrit) {
        try indentWriter(stdout, verse.Object.get("sanskrit").?.String, 4);
    }

    if (option.english) {
        try indentWriter(stdout, verse.Object.get("english").?.String, 4);
    }
}

fn indentWriter(writer: anytype, string: []const u8, indent_size: usize) !void {
    var iter = std.mem.tokenize(u8, string, "\n");
    while (iter.next()) |slice| {
        try writer.writeByteNTimes(' ', indent_size);
        try writer.print("{s}\n", .{slice});
    }
}
