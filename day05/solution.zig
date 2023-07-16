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
    defer allocator.free(r1);
    try stdout.print("Part 1:\n{s}\n", .{r1});
    const r2 = try part2(allocator, input);
    defer allocator.free(r2);
    try stdout.print("Part 2:\n{s}\n", .{r2});
}

const Crates = struct {
    stacks: []std.ArrayList(u8),

    // Allocated Crate is owned by caller.
    fn parse(allocator: std.mem.Allocator, text: []const u8) !Crates {
        const lineLen = std.mem.indexOf(u8, text, "\n").?;
        const numStacks = (lineLen + 1) / 4;
        const stacks: []std.ArrayList(u8) = try allocator.alloc(std.ArrayList(u8), numStacks);

        var i: usize = 0;
        while (i < numStacks) : (i += 1) {
            stacks[i] = std.ArrayList(u8).init(allocator);
        }

        // Walk backwards from the bottom of the crates to the top of the
        // crates. Ignore the bottom line (which are the numerical labels).
        const numLines = text.len / lineLen;
        i = numLines - 2;
        while (true) : (i -= 1) {
            // +1 to linelen to account for newlines.
            const line = text[i * (lineLen + 1) .. (i + 1) * (lineLen + 1)];
            // stack * 4 + 1 represents the index of the stack's crate in the string.
            var stack: usize = 0;
            while (stack < numStacks) : (stack += 1) {
                const char = line[stack * 4 + 1];
                if (char != ' ') {
                    try stacks[stack].append(char);
                }
            }
            // Break here instead of in while because we cannot go to negative usize.
            if (i == 0) break;
        }

        return Crates{ .stacks = stacks };
    }

    fn free(self: Crates, allocator: std.mem.Allocator) void {
        for (self.stacks) |stack| stack.deinit();
        allocator.free(self.stacks);
    }

    // Allocated slice is owned by caller.
    fn readTopLine(self: Crates, allocator: std.mem.Allocator) ![]u8 {
        var topline: []u8 = try allocator.alloc(u8, self.stacks.len);
        var i: usize = 0;
        while (i < self.stacks.len) : (i += 1) {
            topline[i] = self.stacks[i].pop();
        }
        return topline;
    }
};

const Move = struct {
    numToMove: u32,
    fromStack: u32,
    toStack: u32,

    fn parse(move: []const u8) !Move {
        // move {numToMove} from {fromStackIdx} to {toStackIdx}
        var words = std.mem.split(u8, move, " ");
        _ = words.next();
        const numToMove = try std.fmt.parseInt(u32, words.next().?, 10);
        _ = words.next();
        const fromStack = try std.fmt.parseInt(u32, words.next().?, 10);
        _ = words.next();
        const toStack = try std.fmt.parseInt(u32, words.next().?, 10);

        return Move{
            .numToMove = numToMove,
            .fromStack = fromStack,
            .toStack = toStack,
        };
    }
};

// The return value belongs to the caller.
fn part1(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    var it = std.mem.split(u8, input, "\n\n");

    const diagramText = it.next().?;
    var crates = try Crates.parse(allocator, diagramText);
    defer crates.free(allocator);

    const movesText = it.next().?;
    var moves = std.mem.split(u8, movesText, "\n");
    while (moves.next()) |moveText| {
        const move = try Move.parse(moveText);
        var i: usize = 0;
        while (i < move.numToMove) : (i += 1) {
            try crates.stacks[move.toStack - 1].append(crates.stacks[move.fromStack - 1].pop());
        }
    }

    return try crates.readTopLine(allocator);
}

fn part2(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    var it = std.mem.split(u8, input, "\n\n");

    const diagramText = it.next().?;
    var crates = try Crates.parse(allocator, diagramText);
    defer crates.free(allocator);

    const movesText = it.next().?;
    var moves = std.mem.split(u8, movesText, "\n");
    while (moves.next()) |moveText| {
        const move = try Move.parse(moveText);
        const fromStack = &crates.stacks[move.fromStack - 1];
        const toStack = &crates.stacks[move.toStack - 1];
        const idxToSwapRemove = fromStack.items.len - move.numToMove;
        var i: usize = 0;
        while (i < move.numToMove) : (i += 1) {
            try toStack.*.append(fromStack.*.orderedRemove(idxToSwapRemove));
        }
    }

    return try crates.readTopLine(allocator);
}

const exampleInput = std.mem.trim(u8, @embedFile("./input.example"), "\n");
test part1 {
    const allocator = std.heap.page_allocator;
    const result = try part1(allocator, exampleInput);
    try std.testing.expect(std.mem.eql(u8, result, "CMZ"));
    allocator.free(result);
}
test part2 {
    const allocator = std.heap.page_allocator;
    const result = try part2(allocator, exampleInput);
    try std.testing.expect(std.mem.eql(u8, result, "MCD"));
    allocator.free(result);
}
