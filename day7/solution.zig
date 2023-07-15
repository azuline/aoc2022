// God this is so unperformant, I need a better traversal, BUT I SUCK
// AT ZIG AND DONT KNOW HOW TO WALK A TREE.

const std = @import("std");

const Error = error{
    InvalidInput,
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var stdin = std.io.getStdIn().reader();
    var stdout = std.io.getStdOut().writer();
    var bufferedReader = std.io.bufferedReader(stdin);
    const inputReader = bufferedReader.reader();
    const rawInput = try inputReader.readAllAlloc(allocator, 1048576);
    defer allocator.free(rawInput);
    const input = std.mem.trim(u8, rawInput, "\n");

    const r1 = try part1(allocator, input);
    try stdout.print("Part 1:\n{}\n", .{r1});
    const r2 = try part2(allocator, input);
    try stdout.print("Part 2:\n{}\n", .{r2});
}

const File = struct {
    name: []const u8,
    size: usize,
};

const Directory = struct {
    name: []const u8,
    parent: ?*Directory,
    subdirs: std.ArrayList(*Directory),
    // Slice of the file sizes.
    subfiles: std.ArrayList(*File),

    // TODO: This can be cached. Too bad I suck at Zig.
    fn size(self: Directory) usize {
        var s: usize = 0;
        for (self.subfiles.items) |f| s += f.size;
        for (self.subdirs.items) |d| s += d.size();
        return s;
    }

    // mkdir creates a subdir, doing nothing if it already exists.
    fn mkdir(self: *Directory, allocator: std.mem.Allocator, name: []const u8) !void {
        for (self.subdirs.items) |d| {
            if (std.mem.eql(u8, d.name, name)) return;
        }
        try self.subdirs.append(try Directory.init(allocator, name, self));
    }

    // touch creates a subfile, doing nothing if it already exists.
    fn touch(self: *Directory, allocator: std.mem.Allocator, name: []const u8, size_: usize) !void {
        for (self.subfiles.items) |f| {
            if (std.mem.eql(u8, f.name, name)) return;
        }
        var f: *File = try allocator.create(File);
        f.* = File{ .name = name, .size = size_ };
        try self.subfiles.append(f);
    }

    fn cd(self: *Directory, name: []const u8) ?*Directory {
        for (self.subdirs.items) |d| {
            if (std.mem.eql(u8, d.name, name)) return d;
        }
        return null;
    }

    fn init(allocator: std.mem.Allocator, name: []const u8, parent: ?*Directory) !*Directory {
        var d: *Directory = try allocator.create(Directory);
        d.* = Directory{
            .name = name,
            .parent = parent,
            .subdirs = std.ArrayList(*Directory).init(allocator),
            .subfiles = std.ArrayList(*File).init(allocator),
        };
        return d;
    }

    fn deinit(self: Directory, allocator: std.mem.Allocator) void {
        for (self.subdirs.items) |d| allocator.destroy(d);
        for (self.subfiles.items) |f| allocator.destroy(f);
        self.subdirs.deinit();
        self.subfiles.deinit();
    }
};

// parse's return value owned by caller.
fn parse(allocator: std.mem.Allocator, input: []const u8) !*Directory {
    var it = std.mem.split(u8, input, "\n$ ");
    // Discard `$ cd /`.
    _ = it.next();
    var root = try Directory.init(allocator, "/", null);
    var cd: *Directory = root;
    while (it.next()) |cmd| {
        if (std.mem.startsWith(u8, cmd, "ls")) {
            var lines = std.mem.split(u8, cmd, "\n");
            // Discard `ls`.
            _ = lines.next();
            while (lines.next()) |line| {
                var words = std.mem.split(u8, line, " ");
                const w1 = words.next().?;
                const w2 = words.next().?;
                if (std.mem.eql(u8, w1, "dir")) {
                    try cd.mkdir(allocator, w2);
                } else {
                    try cd.touch(allocator, w2, try std.fmt.parseInt(usize, w1, 10));
                }
            }
        } else if (std.mem.startsWith(u8, cmd, "cd")) {
            const dest = cmd[3..];
            cd = if (std.mem.eql(u8, dest, "..")) cd.parent.? else cd.cd(dest).?;
        } else {
            return Error.InvalidInput;
        }
    }
    return root;
}

fn part1(allocator: std.mem.Allocator, input: []const u8) !usize {
    const root = try parse(allocator, input);
    defer root.deinit(allocator);
    return sumSizesBelow100k(root);
}

fn sumSizesBelow100k(root: *Directory) usize {
    var sum: usize = 0;
    for (root.subdirs.items) |d| {
        var dsize = d.size();
        if (dsize <= 100_000) {
            sum += dsize;
        }
        sum += sumSizesBelow100k(d);
    }
    return sum;
}

fn part2(allocator: std.mem.Allocator, input: []const u8) !usize {
    const root = try parse(allocator, input);
    defer root.deinit(allocator);
    const totalSpace = 70_000_000;
    const desiredSpace = 30_000_000;
    const delta: usize = root.size() - (totalSpace - desiredSpace);
    return try findSmallestSizeAboveDelta(root, delta);
}

fn findSmallestSizeAboveDelta(root: *Directory, delta: usize) !usize {
    var smallest: usize = root.size();
    for (root.subdirs.items) |d| {
        var dsize = d.size();
        if (dsize < delta) continue;
        if (dsize < smallest) smallest = dsize;
        const recResult = try findSmallestSizeAboveDelta(d, delta);
        if (recResult < smallest) smallest = recResult;
    }
    return smallest;
}

const exampleInput = std.mem.trim(u8, @embedFile("./input.example"), "\n");
test part1 {
    const allocator = std.heap.page_allocator;
    const result = try part1(allocator, exampleInput);
    std.debug.print("result: {}\n", .{result});
    try std.testing.expect(result == 95437);
}
test part2 {
    const allocator = std.heap.page_allocator;
    const result = try part2(allocator, exampleInput);
    std.debug.print("result: {}\n", .{result});
    try std.testing.expect(result == 24933642);
}
