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

const Direction = enum { U, R, D, L };
const Move = struct { direction: Direction, steps: u32 };
const Coord = struct { x: i32, y: i32 };

// Return value owned by caller.
fn parse(allocator: std.mem.Allocator, input: []const u8) ![]Move {
    var numMoves = std.mem.count(u8, input, "\n") + 1;
    var moves = try allocator.alloc(Move, numMoves);
    var it = std.mem.split(u8, input, "\n");
    var idx: usize = 0;
    while (it.next()) |line| {
        const direction = switch (line[0]) {
            'U' => Direction.U,
            'R' => Direction.R,
            'D' => Direction.D,
            'L' => Direction.L,
            else => return Error.InvalidInput,
        };
        const steps = try std.fmt.parseInt(u32, line[2..], 10);
        moves[idx] = Move{ .direction = direction, .steps = steps };
        idx += 1;
    }
    return moves;
}

fn movehead(direction: Direction, head: *Coord) void {
    switch (direction) {
        Direction.U => head.y += 1,
        Direction.R => head.x += 1,
        Direction.D => head.y -= 1,
        Direction.L => head.x -= 1,
    }
}

fn movetail(head: *Coord, tail: *Coord) !void {
    const xgap = try std.math.absInt(head.x - tail.x) == 2;
    const ygap = try std.math.absInt(head.y - tail.y) == 2;

    // We have three possible cases:
    // 1. There is an xgap AND a ygap.
    // 2. There is an xgap OR a ygap.
    // 3. There is no gap.
    //
    // 3. is trivial.
    // 2. means we move to bridge the gap that appeared, and in order to
    //    support diagonal movement, we can move the tail to equal the head on the
    //    non-movement axis.
    // 1. Means that the tail should move fully diagonally, which means we do
    //    not do the non-movement axis snapping thing from 2.
    if (xgap) {
        tail.x += if (head.x > tail.x) 1 else -1;
        if (!ygap) tail.y = head.y;
    }
    if (ygap) {
        tail.y += if (head.y > tail.y) 1 else -1;
        if (!xgap) tail.x = head.x;
    }
}

fn part1(allocator: std.mem.Allocator, input: []const u8) !usize {
    const moves = try parse(allocator, input);
    var head = Coord{ .x = 0, .y = 0 };
    var tail = Coord{ .x = 0, .y = 0 };
    var visited = std.AutoHashMap(Coord, void).init(allocator);
    try visited.put(tail, {});
    for (moves) |m| {
        var step: usize = 0;
        while (step < m.steps) : (step += 1) {
            // Invariant: After a completed "movement", abs(hx-tx) < 2 and abs(hy-ty) < 2.
            movehead(m.direction, &head);
            try movetail(&head, &tail);
            try visited.put(tail, {});
        }
    }
    return visited.count();
}

fn part2(allocator: std.mem.Allocator, input: []const u8) !usize {
    const moves = try parse(allocator, input);
    var knots = std.mem.zeroes([10]Coord);
    var visited = std.AutoHashMap(Coord, void).init(allocator);
    try visited.put(knots[9], {});
    for (moves) |m| {
        var step: usize = 0;
        while (step < m.steps) : (step += 1) {
            movehead(m.direction, &knots[0]);
            var i: usize = 0;
            while (i < 9) : (i += 1) {
                try movetail(&knots[i], &knots[i + 1]);
            }
            try visited.put(knots[9], {});
        }
    }
    return visited.count();
}

const exampleInput1 = std.mem.trim(u8, @embedFile("./input1.example"), "\n");
test part1 {
    const allocator = std.heap.page_allocator;
    const result = try part1(allocator, exampleInput1);
    std.debug.print("result: {}\n", .{result});
    try std.testing.expect(result == 13);
}
const exampleInput2 = std.mem.trim(u8, @embedFile("./input2.example"), "\n");
test part2 {
    const allocator = std.heap.page_allocator;
    const result = try part2(allocator, exampleInput2);
    std.debug.print("result: {}\n", .{result});
    try std.testing.expect(result == 36);
}
