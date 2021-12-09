const std = @import("std");
const Answer = struct { @"0": u32, @"1": u32 };

const dirs = [4][2]i32{ [_]i32{ 0, 1 }, [_]i32{ 0, -1 }, [_]i32{ 1, 0 }, [_]i32{ -1, 0 } };

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

    for (cave.items) |row| {
        std.debug.print("{any}\n", .{row.items});
    }

    var total: u32 = 0;
    var i: usize = 0;
    while (i < cave.items.len) : (i += 1) {
        var j: usize = 0;
        cell_loop: while (j < cave.items[i].items.len) : (j += 1) {
            for (dirs) |dir| {
                if (0 <= @intCast(i32, i) + dir[0] and @intCast(i32, i) + dir[0] < cave.items.len and 0 <= @intCast(i32, j) + dir[1] and @intCast(i32, j) + dir[1] < cave.items[i].items.len) {
                    if (cave.items[i].items[j] >= cave.items[@intCast(usize, @intCast(i32, i) + dir[0])].items[@intCast(usize, @intCast(i32, j) + dir[1])]) {
                        // std.debug.print("{d} {d}\n", .{ i, j });
                        continue :cell_loop;
                    }
                }
            }
            total += cave.items[i].items[j] + 1;
            std.debug.print("\n", .{});
        }
    }

    return Answer{ .@"0" = total, .@"1" = 0 };
}

pub fn main() !void {
    const answer = try run("inputs/" ++ @typeName(@This()) ++ ".txt");
    std.debug.print("{d}\n", .{answer.@"0"});
    std.debug.print("{d}\n", .{answer.@"1"});
}

test {
    const answer = try run("test-inputs/" ++ @typeName(@This()) ++ ".txt");
    try std.testing.expectEqual(@as(u32, 15), answer.@"0");
    // try std.testing.expectEqual(@as(u32, 61229), answer.@"1");
}
