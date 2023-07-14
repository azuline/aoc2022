const std = @import("std");

const megabyte = 1048576;

const Error = error{
    InvalidInput,
};

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
    var score: u32 = 0;

    var plays = std.mem.split(u8, input, "\n");
    while (plays.next()) |play| {
        const opponentMove: u8 = play[0] - 'A' + 1;
        const playerMove: u8 = play[2] - 'X' + 1;

        score += playerMove;
        // Note on the else if: After wrapping the opponent's scissor down to 0
        // (via the modulo 3), the player's winning move is always 1 greater
        // than the opponent's move.
        if (opponentMove == playerMove) {
            score += 3;
        } else if (playerMove - 1 == (opponentMove % 3)) {
            score += 6;
        }
    }

    return score;
}

fn part2(input: []const u8) !u32 {
    var score: u32 = 0;

    var plays = std.mem.split(u8, input, "\n");
    while (plays.next()) |play| {
        const opponentMove: u8 = play[0] - 'A' + 1;
        switch (play[2]) {
            // Lose.
            'X' => {
                score += if (opponentMove == 1) 3 else opponentMove - 1;
            },
            // Draw.
            'Y' => {
                score += 3 + opponentMove;
            },
            // Win.
            'Z' => {
                score += 6 + (opponentMove % 3) + 1;
            },
            else => return Error.InvalidInput,
        }
    }

    return score;
}

const exampleInput = std.mem.trim(u8, @embedFile("./input.example"), "\n");
test part1 {
    try std.testing.expect((try part1(exampleInput)) == 15);
}
test part2 {
    try std.testing.expect((try part2(exampleInput)) == 12);
}
