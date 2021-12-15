const std = @import("std");
const Answer = struct { @"0": u32, @"1": u32 };

const AugmentedPoint = struct { x: usize, y: usize, cost: u32 };
const Point = struct { x: usize, y: usize };

fn wrappingAdd(x: u32, a: u32) u32 {
    if (x + a > 9) {
        return (x + a) % 9;
    } else {
        return x + a;
    }
}

fn fromAugmented(p: AugmentedPoint) Point {
    return Point{ .x = p.x, .y = p.y };
}

fn displace(p: Point, displacement: [2]i32) ?Point {
    if (displacement[0] < 0 and -displacement[0] > p.x) {
        return null;
    } else if (displacement[1] < 0 and -displacement[1] > p.y) {
        return null;
    } else {
        return Point{ .x = @intCast(usize, @intCast(i32, p.x) + displacement[0]), .y = @intCast(usize, @intCast(i32, p.y) + displacement[1]) };
    }
}

fn augment(p: Point, cost: u32) AugmentedPoint {
    return AugmentedPoint{ .x = p.x, .y = p.y, .cost = cost };
}

fn lessThan(a: AugmentedPoint, b: AugmentedPoint) std.math.Order {
    return std.math.order(a.cost, b.cost);
}

fn search(grid: std.ArrayList(std.ArrayList(u32)), arena: *std.heap.ArenaAllocator) !u32 {
    var node = AugmentedPoint{ .x = 0, .y = 0, .cost = 0 };
    var frontier = std.PriorityQueue(AugmentedPoint, lessThan).init(&arena.allocator);
    try frontier.add(node);
    var explored = std.AutoHashMap(Point, void).init(&arena.allocator);
    try explored.put(fromAugmented(node), .{});
    while (frontier.removeOrNull()) |next_node| {
        node = next_node;
        if (node.y == grid.items.len - 1 and node.x == grid.items[0].items.len - 1) {
            return node.cost;
        }
        for ([4][2]i32{ [_]i32{ 1, 0 }, [_]i32{ 0, 1 }, [_]i32{ -1, 0 }, [_]i32{ 0, -1 } }) |displacement| {
            if (displace(fromAugmented(node), displacement)) |displaced_node| {
                if (displaced_node.x < grid.items[0].items.len and displaced_node.y < grid.items.len) {
                    if (!explored.contains(displaced_node)) {
                        try frontier.add(augment(displaced_node, grid.items[displaced_node.y].items[displaced_node.x] + node.cost));
                        try explored.put(displaced_node, .{});
                    }
                }
            }
        }
    } else {
        unreachable;
    }
}

fn run(filename: []const u8) !Answer {
    const file = try std.fs.cwd().openFile(filename, .{ .read = true });
    defer file.close();

    var reader = std.io.bufferedReader(file.reader()).reader();
    var buffer: [1024]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(&gpa.allocator);
    defer arena.deinit();

    var grid = std.ArrayList(std.ArrayList(u32)).init(&arena.allocator);

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var row = std.ArrayList(u32).init(&arena.allocator);
        for (line) |c| {
            try row.append(@as(u32, c - '0'));
        }
        try grid.append(row);
    }

    var big_grid = std.ArrayList(std.ArrayList(u32)).init(&arena.allocator);
    var i: usize = 0;
    while (i < grid.items.len * 5) : (i += 1) {
        var big_row = std.ArrayList(u32).init(&arena.allocator);
        var j: usize = 0;
        while (j < grid.items[0].items.len * 5) : (j += 1) {
            const height = grid.items.len;
            const width = grid.items[0].items.len;
            try big_row.append(wrappingAdd(grid.items[i % height].items[j % width], @intCast(u32, i / height + j / width)));
        }
        try big_grid.append(big_row);
    }

    return Answer{ .@"0" = try search(grid, &arena), .@"1" = try search(big_grid, &arena) };
}

pub fn main() !void {
    const answer = try run("inputs/" ++ @typeName(@This()) ++ ".txt");
    std.debug.print("{d}\n", .{answer.@"0"});
    std.debug.print("{d}\n", .{answer.@"1"});
}

test {
    const answer = try run("test-inputs/" ++ @typeName(@This()) ++ ".txt");
    try std.testing.expectEqual(answer.@"0", 40);
    try std.testing.expectEqual(answer.@"1", 315);
}
