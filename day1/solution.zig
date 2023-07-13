const std = @import("std");

const megabyte = 1048576;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var stdin = std.io.getStdIn().reader();
    var stdout = std.io.getStdOut().writer();
    var bufferedReader = std.io.bufferedReader(stdin);
    const inputReader = bufferedReader.reader();
    const rawInput = try inputReader.readAllAlloc(allocator, megabyte);
    const input = std.mem.trim(u8, rawInput, "\n");

    const r1 = try part1(input);
    try stdout.print("Part 1:\n{}\n", .{r1});
    const r2 = try part2(input);
    try stdout.print("Part 2:\n{}\n", .{r2});
}

fn part1(input: []const u8) !u32 {
    var max: u32 = 0;

    var inventories = std.mem.split(u8, input, "\n\n");
    while (inventories.next()) |inventory| {
        var items = std.mem.split(u8, inventory, "\n");
        var sum: u32 = 0;
        while (items.next()) |item| {
            sum += try std.fmt.parseInt(u32, item, 10);
        }
        max = std.math.max(sum, max);
    }

    return max;
}

fn part2(input: []const u8) !u32 {
    var first: u32 = 0;
    var second: u32 = 0;
    var third: u32 = 0;

    var inventories = std.mem.split(u8, input, "\n\n");
    while (inventories.next()) |inventory| {
        var items = std.mem.split(u8, inventory, "\n");
        var sum: u32 = 0;
        while (items.next()) |item| {
            sum += try std.fmt.parseInt(u32, item, 10);
        }
        if (sum >= third) {
            third = sum;
        }
        if (sum >= second) {
            third = second;
            second = sum;
        }
        if (sum >= first) {
            second = first;
            first = sum;
        }
    }

    return first + second + third;
}

const exampleInput = std.mem.trim(u8, @embedFile("./input.example"), "\n");
test part1 {
    try std.testing.expect((try part1(exampleInput)) == 24000);
}
test part2 {
    try std.testing.expect((try part2(exampleInput)) == 45000);
}
