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
