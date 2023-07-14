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
    const input = std.mem.trim(u8, rawInput, "\n");

    const r1 = try part1(input);
    try stdout.print("Part 1:\n{}\n", .{r1});
    const r2 = try part2(input);
    try stdout.print("Part 2:\n{}\n", .{r2});
}

fn part1(input: []const u8) !u32 {
    var prioritySum: u32 = 0;
    var rucksacks = std.mem.split(u8, input, "\n");
    while (rucksacks.next()) |rucksack| {
        const halfway = rucksack.len / 2;
        const firstSack = rucksack[0..halfway];
        const secondSack = rucksack[halfway..rucksack.len];
        // Use a for loop over a set b/c it should have good locality.
        loop: for (firstSack) |x| {
            for (secondSack) |y| {
                if (x == y) {
                    prioritySum += calculatePriority(x);
                    break :loop;
                }
            }
        }
    }
    return prioritySum;
}

fn part2(input: []const u8) !u32 {
    var prioritySum: u32 = 0;
    var rucksacks = std.mem.split(u8, input, "\n");
    var done = false;
    while (!done) {
        const firstSack = rucksacks.next();
        const secondSack = rucksacks.next();
        const thirdSack = rucksacks.next();
        if (firstSack == null or secondSack == null or thirdSack == null) {
            break;
        }
        // Use a for loop over a set b/c it should have good locality.
        loop: for (firstSack.?) |x| {
            for (secondSack.?) |y| {
                if (x != y) {
                    continue;
                }
                for (thirdSack.?) |z| {
                    if (x == y and y == z) {
                        prioritySum += calculatePriority(x);
                        break :loop;
                    }
                }
            }
        }
    }
    return prioritySum;
}

fn calculatePriority(x: u8) u8 {
    return if (x <= 'Z') x - 'A' + 27 else x - 'a' + 1;
}
test calculatePriority {
    try std.testing.expect(calculatePriority('a') == 1);
    try std.testing.expect(calculatePriority('z') == 26);
    try std.testing.expect(calculatePriority('A') == 27);
    try std.testing.expect(calculatePriority('Z') == 52);
}

const exampleInput = std.mem.trim(u8, @embedFile("./input.example"), "\n");
test part1 {
    try std.testing.expect((try part1(exampleInput)) == 157);
}
test part2 {
    try std.testing.expect((try part2(exampleInput)) == 70);
}
