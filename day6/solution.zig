const std = @import("std");

const Error = error{
    FailedToFindResult,
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

    const r1 = try part1(input);
    try stdout.print("Part 1:\n{}\n", .{r1});
    const r2 = try part2(input);
    try stdout.print("Part 2:\n{}\n", .{r2});
}

fn part1(input: []const u8) !usize {
    return try findMarker(input, 4);
}

fn part2(input: []const u8) !usize {
    return try findMarker(input, 14);
}

fn findMarker(input: []const u8, comptime markerSize: usize) !usize {
    var memory: [markerSize]u8 = undefined;
    var i: usize = 0;
    while (i < input.len) : (i += 1) {
        memory[i % markerSize] = input[i];
        if (i < markerSize) continue;
        loop: for (memory) |mx, mi| {
            for (memory[mi + 1 ..]) |my| {
                if (mx == my) break :loop;
            }
        } else {
            return i + 1;
        }
    }
    return Error.FailedToFindResult;
}

const exampleInput = std.mem.trim(u8, @embedFile("./input.example"), "\n");
test part1 {
    const result = try part1(exampleInput);
    std.debug.print("result: {}\n", .{result});
    try std.testing.expect(result == 7);
}
test part2 {
    const result = try part2(exampleInput);
    std.debug.print("result: {}\n", .{result});
    try std.testing.expect(result == 19);
}
