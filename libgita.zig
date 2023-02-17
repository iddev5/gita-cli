const std = @import("std");
const source = @embedFile("gita.json");

const LibGita = @This();

pub const Options = struct {
    sanskrit: bool = true,
    english: bool = true,
    no_name: bool = false,
    no_tag: bool = false,
    inlined: bool = false,
    indent: u8 = 4,
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

pub fn deinit(lib: *LibGita) void {
    lib.tree.deinit();
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

fn printVerseRaw(options: LibGita.Options, verse: std.json.Value, writer: anytype) !void {
    if (!options.no_name) {
        try writer.writeAll("Bhagavad Gita: ");
    }

    if (!options.no_tag) {
        try writer.print("{}.{}: ", .{ 1, 1 });
    }

    if (@boolToInt(options.no_name) & @boolToInt(options.no_tag) == 0 and !options.inlined)
        try writer.writeAll("\n\n");

    const indent = if (options.inlined) 0 else options.indent;

    if (options.sanskrit) {
        try indentWriter(writer, verse.Object.get("sanskrit").?.String, indent, options.inlined);
        if (options.english)
            try writer.writeByte(if (options.inlined) ' ' else '\n');
    }

    if (options.english) {
        try indentWriter(writer, verse.Object.get("english").?.String, indent, options.inlined);
    }
}

fn indentWriter(writer: anytype, string: []const u8, indent_size: usize, inlined: bool) !void {
    var iter = std.mem.tokenize(u8, string, "\n");
    while (iter.next()) |slice| {
        try writer.writeByteNTimes(' ', indent_size);
        try writer.print("{s}", .{slice});
        try writer.writeByte(if (inlined) ' ' else '\n');
    }
}
