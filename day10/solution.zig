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
    try stdout.print("Part 2:\n{s}\n", .{r2});
}

const Computer = struct {
    regx: i32,
    cycle: usize,
    signalStrengths: i32,
    crt: [240]u8,

    fn init() Computer {
        return Computer{
            .regx = 1,
            .cycle = 0,
            .signalStrengths = 0,
            .crt = [_]u8{'.'} ** 240,
        };
    }

    fn noop(self: *Computer) void {
        self.cycle += 1;
        // Part 1: Signal strength
        if (self.cycle % 40 == 20) {
            const product = @as(i32, @intCast(self.cycle)) * self.regx;
            self.signalStrengths += product;
        }
        // Part 2: CRT monitor
        const xpos = (self.cycle - 1) % 40;
        if (self.cycle < 240 and self.regx - 1 <= xpos and xpos <= self.regx + 1) {
            self.crt[self.cycle - 1] = '#';
        }
    }

    fn addx(self: *Computer, operand: i32) void {
        self.noop();
        self.noop();
        self.regx += operand;
    }

    fn processLine(self: *Computer, line: []const u8) !void {
        if (std.mem.startsWith(u8, line, "noop")) {
            self.noop();
        } else if (std.mem.startsWith(u8, line, "addx")) {
            self.addx(try std.fmt.parseInt(i32, line[5..], 10));
        }
    }

    fn image(self: *Computer) [247:0]u8 {
        var i: usize = 0;
        var display = std.mem.zeroes([247:0]u8);
        while (i < 6) : (i += 1) {
            std.mem.copy(u8, display[(i * 40 + i + 1) .. (i + 1) * 40 + i + 1], self.crt[i * 40 .. (i + 1) * 40]);
            display[(i + 1) * 40 + i + 1] = '\n';
        }
        return display;
    }
};

fn part1(_: std.mem.Allocator, input: []const u8) !i32 {
    var it = std.mem.split(u8, input, "\n");
    var cpu = Computer.init();
    while (it.next()) |line| try cpu.processLine(line);
    return cpu.signalStrengths;
}

fn part2(_: std.mem.Allocator, input: []const u8) ![247:0]u8 {
    var it = std.mem.split(u8, input, "\n");
    var cpu = Computer.init();
    while (it.next()) |line| try cpu.processLine(line);
    return cpu.image();
}

const exampleInput = std.mem.trim(u8, @embedFile("./input.example"), "\n");
test part1 {
    const allocator = std.heap.page_allocator;
    const result = try part1(allocator, exampleInput);
    std.debug.print("result: {}\n", .{result});
    try std.testing.expect(result == 13140);
}
test part2 {
    const allocator = std.heap.page_allocator;
    const result = try part2(allocator, exampleInput);
    std.debug.print("result: \n{s}", .{result});
    std.debug.print("expect: \n{s}", .{
        \\##..##..##..##..##..##..##..##..##..##..
        \\###...###...###...###...###...###...###.
        \\####....####....####....####....####....
        \\#####.....#####.....#####.....#####.....
        \\######......######......######......####
        \\#######.......#######.......#######.....
        \\
    });
}
