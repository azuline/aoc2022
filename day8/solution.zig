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

const Direction = enum { Up, Down, Left, Right };
const Coord = struct { x: usize, y: usize };
const Key = struct { direction: Direction, coord: Coord };

const Map = struct {
    width: usize,
    height: usize,
    trees: std.AutoHashMap(Coord, i32),

    // construct's returned hash map is owned by caller.
    fn construct(allocator: std.mem.Allocator, input: []const u8) !Map {
        const width = std.mem.indexOf(u8, input, "\n").?;
        const height = input.len / width;
        var trees = std.AutoHashMap(Coord, i32).init(allocator);
        var y: usize = 0;
        while (y < height) : (y += 1) {
            var x: usize = 0;
            while (x < width) : (x += 1) {
                const char = input[y * (width + 1) + x];
                try trees.put(Coord{ .x = x, .y = y }, char - '0');
            }
        }
        return Map{ .width = width, .height = height, .trees = trees };
    }
};

fn part1(allocator: std.mem.Allocator, input: []const u8) !usize {
    var map = try Map.construct(allocator, input);
    // Then check to see if the element in the map is above the sightline.
    // The sightlines HashMap memoize the calculations.
    var sightlines = std.AutoHashMap(Key, i32).init(allocator);
    var numvisible: usize = 0;
    var y: usize = 0;
    while (y < map.height) : (y += 1) {
        var x: usize = 0;
        while (x < map.width) : (x += 1) {
            for ([_]Direction{ Direction.Up, Direction.Down, Direction.Left, Direction.Right }) |direction| {
                const coord = Coord{ .x = x, .y = y };
                if (map.trees.get(coord).? > try computeSightline(&sightlines, map, direction, coord)) {
                    numvisible += 1;
                    break;
                }
            }
        }
    }
    return numvisible;
}

// computeSightline computes the sightline and updates the sightlines hashmap
// with the knowns sightlines. If the sightline is already in the HashMap, it
// is simply returned (cache hit).
fn computeSightline(sightlines: *std.AutoHashMap(Key, i32), map: Map, direction: Direction, coord: Coord) !i32 {
    if (sightlines.get(Key{ .direction = direction, .coord = coord })) |height| return height;
    var nextCoord = switch (direction) {
        Direction.Up => if (coord.y != 0) Coord{ .x = coord.x, .y = coord.y - 1 } else null,
        Direction.Down => if (coord.y != map.height - 1) Coord{ .x = coord.x, .y = coord.y + 1 } else null,
        Direction.Left => if (coord.x != 0) Coord{ .x = coord.x - 1, .y = coord.y } else null,
        Direction.Right => if (coord.x != map.width - 1) Coord{ .x = coord.x + 1, .y = coord.y } else null,
    } orelse return -1;
    const sightline = std.math.max(
        try computeSightline(sightlines, map, direction, nextCoord),
        map.trees.get(nextCoord).?,
    );
    try sightlines.put(Key{ .direction = direction, .coord = coord }, sightline);
    return sightline;
}

fn part2(allocator: std.mem.Allocator, input: []const u8) !usize {
    var map = try Map.construct(allocator, input);
    var highestScenicScore: usize = 0;
    var y: usize = 0;
    while (y < map.height) : (y += 1) {
        var x: usize = 0;
        while (x < map.width) : (x += 1) {
            var scenicScore: usize = 1;
            for ([_]Direction{ Direction.Up, Direction.Down, Direction.Left, Direction.Right }) |direction| {
                const coord = Coord{ .x = x, .y = y };
                const coordHeight = map.trees.get(coord).?;
                var treesVisibleInDirection: usize = 0;
                var nextCoord = coord;
                while (0 < nextCoord.x and nextCoord.x < map.width - 1 and 0 < nextCoord.y and nextCoord.y < map.height - 1) {
                    treesVisibleInDirection += 1;
                    switch (direction) {
                        Direction.Up => nextCoord.y -= 1,
                        Direction.Down => nextCoord.y += 1,
                        Direction.Left => nextCoord.x -= 1,
                        Direction.Right => nextCoord.x += 1,
                    }
                    const nextCoordHeight = map.trees.get(nextCoord).?;
                    if (nextCoordHeight >= coordHeight) break;
                }
                scenicScore *= treesVisibleInDirection;
            }
            highestScenicScore = std.math.max(highestScenicScore, scenicScore);
        }
    }
    return highestScenicScore;
}

const exampleInput = std.mem.trim(u8, @embedFile("./input.example"), "\n");
test part1 {
    const allocator = std.heap.page_allocator;
    const result = try part1(allocator, exampleInput);
    std.debug.print("result: {}\n", .{result});
    try std.testing.expect(result == 21);
}
test part2 {
    const allocator = std.heap.page_allocator;
    const result = try part2(allocator, exampleInput);
    std.debug.print("result: {}\n", .{result});
    try std.testing.expect(result == 8);
}
