const std = @import("std");
const Answer = struct { @"0": u32, @"1": u32 };

const dirs = [4][2]i32{ [_]i32{ 0, 1 }, [_]i32{ 0, -1 }, [_]i32{ 1, 0 }, [_]i32{ -1, 0 } };
const Point = struct { x: usize, y: usize };

fn pointEquals(p: Point, q: Point) bool {
    return p.x == q.x and p.y == q.y;
}

fn run(filename: []const u8) !Answer {
    const file = try std.fs.cwd().openFile(filename, .{ .read = true });
    defer file.close();

    var reader = std.io.bufferedReader(file.reader()).reader();
    var buffer: [4096]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(&gpa.allocator);
    defer arena.deinit();

    var cave = std.ArrayList(std.ArrayList(u32)).init(&arena.allocator);

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var row = std.ArrayList(u32).init(&arena.allocator);
        var i: usize = 0;
        while (i < line.len) : (i += 1) {
            try row.append(try std.fmt.parseInt(u32, line[i .. i + 1], 10));
        }
        try cave.append(row);
    }

    var total: u32 = 0;
    var i: usize = 0;
    while (i < cave.items.len) : (i += 1) {
        var j: usize = 0;
        cell_loop: while (j < cave.items[i].items.len) : (j += 1) {
            for (dirs) |dir| {
                if (0 <= @intCast(i32, i) + dir[0] and @intCast(i32, i) + dir[0] < cave.items.len and 0 <= @intCast(i32, j) + dir[1] and @intCast(i32, j) + dir[1] < cave.items[i].items.len) {
                    if (cave.items[i].items[j] >= cave.items[@intCast(usize, @intCast(i32, i) + dir[0])].items[@intCast(usize, @intCast(i32, j) + dir[1])]) {
                        continue :cell_loop;
                    }
                }
            }
            total += cave.items[i].items[j] + 1;
        }
    }

    var flows = std.AutoHashMap(Point, Point).init(&gpa.allocator);
    defer flows.deinit();

    var basins = std.AutoHashMap(Point, u32).init(&gpa.allocator);
    defer basins.deinit();

    // var total2: u32 = 0;
    i = 0;
    while (i < cave.items.len) : (i += 1) {
        var j: usize = 0;
        while (j < cave.items[i].items.len) : (j += 1) {
            if (cave.items[i].items[j] == 9) {
                continue;
            }

            var min_adj_opt: ?Point = null;
            for (dirs) |dir| {
                if (0 <= @intCast(i32, i) + dir[0] and @intCast(i32, i) + dir[0] < cave.items.len and 0 <= @intCast(i32, j) + dir[1] and @intCast(i32, j) + dir[1] < cave.items[i].items.len) {
                    if (min_adj_opt) |min_adj| {
                        if (cave.items[@intCast(usize, @intCast(i32, i) + dir[0])].items[@intCast(usize, @intCast(i32, j) + dir[1])] < cave.items[min_adj.y].items[min_adj.x]) {
                            min_adj_opt = Point{
                                .x = @intCast(usize, @intCast(i32, j) + dir[1]),
                                .y = @intCast(usize, @intCast(i32, i) + dir[0]),
                            };
                        }
                    } else {
                        min_adj_opt = Point{
                            .x = @intCast(usize, @intCast(i32, j) + dir[1]),
                            .y = @intCast(usize, @intCast(i32, i) + dir[0]),
                        };
                    }
                }
            }

            if (min_adj_opt) |min_adj| {
                if (cave.items[min_adj.y].items[min_adj.x] < cave.items[i].items[j]) {
                    try flows.put(Point{
                        .x = j,
                        .y = i,
                    }, min_adj);
                } else {
                    try flows.put(Point{
                        .x = j,
                        .y = i,
                    }, Point{ .x = j, .y = i });
                }
            }
        }
    }

    i = 0;
    while (i < cave.items.len) : (i += 1) {
        var j: usize = 0;
        while (j < cave.items[i].items.len) : (j += 1) {
            var p = Point{ .x = j, .y = i };

            if (flows.contains(p)) {
                while (!pointEquals(p, flows.get(p).?)) : (p = flows.get(p).?) {}
                if (basins.contains(p)) {
                    try basins.put(p, basins.get(p).? + 1);
                } else {
                    try basins.put(p, 1);
                }
            }
        }
    }

    var basin_sizes = std.ArrayList(u32).init(&gpa.allocator);
    defer basin_sizes.deinit();

    var it = basins.valueIterator();
    while (it.next()) |value_ptr| {
        try basin_sizes.append(value_ptr.*);
    }

    const decreasing = (struct {
        fn decreasing(context: void, a: u32, b: u32) bool {
            _ = context;
            return a > b;
        }
    }).decreasing;

    var top_basin_sizes: u32 = 1;
    std.sort.sort(u32, basin_sizes.items, {}, decreasing);
    i = 0;
    while (i < 3) : (i += 1) {
        top_basin_sizes *= basin_sizes.items[i];
    }

    return Answer{ .@"0" = total, .@"1" = top_basin_sizes };
}

pub fn main() !void {
    const answer = try run("inputs/" ++ @typeName(@This()) ++ ".txt");
    std.debug.print("{d}\n", .{answer.@"0"});
    std.debug.print("{d}\n", .{answer.@"1"});
}

test {
    const answer = try run("test-inputs/" ++ @typeName(@This()) ++ ".txt");
    try std.testing.expectEqual(@as(u32, 15), answer.@"0");
    try std.testing.expectEqual(@as(u32, 1134), answer.@"1");
}
