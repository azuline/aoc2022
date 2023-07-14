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

const Assignment = struct {
    lower: u32,
    upper: u32,

    fn parse(lower: []const u8, upper: []const u8) !Assignment {
        return Assignment{
            .lower = try std.fmt.parseInt(u32, lower, 10),
            .upper = try std.fmt.parseInt(u32, upper, 10),
        };
    }
};

fn part1(input: []const u8) !u32 {
    var count: u32 = 0;
    var assignments = std.mem.split(u8, input, "\n");
    while (assignments.next()) |assignment| {
        // 2-4,6-8 -> [2,4,6,8,null]
        var nums = std.mem.tokenize(u8, assignment, ",-");
        const e1 = try Assignment.parse(nums.next().?, nums.next().?);
        const e2 = try Assignment.parse(nums.next().?, nums.next().?);
        if ((e1.lower <= e2.lower and e1.upper >= e2.upper) or
            (e2.lower <= e1.lower and e2.upper >= e1.upper))
        {
            count += 1;
        }
    }
    return count;
}

fn part2(input: []const u8) !u32 {
    var count: u32 = 0;
    var assignments = std.mem.split(u8, input, "\n");
    while (assignments.next()) |assignment| {
        // 2-4,6-8 -> [2,4,6,8,null]
        var nums = std.mem.tokenize(u8, assignment, ",-");
        const e1 = try Assignment.parse(nums.next().?, nums.next().?);
        const e2 = try Assignment.parse(nums.next().?, nums.next().?);
        if (!(e1.upper < e2.lower or e1.lower > e2.upper)) {
            count += 1;
        }
    }
    return count;
}

const exampleInput = std.mem.trim(u8, @embedFile("./input.example"), "\n");
test part1 {
    try std.testing.expect((try part1(exampleInput)) == 2);
}
test part2 {
    try std.testing.expect((try part2(exampleInput)) == 4);
}
