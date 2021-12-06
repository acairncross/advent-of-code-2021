const std = @import("std");
const Answer = struct { @"0": u64, @"1": u64 };

fn solve(init_buckets: [9]u64, num_days: usize) u64 {
    var buckets = init_buckets;
    var i: usize = 0;
    var today: usize = 0;
    while (i < num_days) : (i += 1) {
        buckets[(today + 7) % 9] += buckets[today];
        today = (today + 1) % 9;
    }

    var total: u64 = 0;
    for (buckets) |num_fish| {
        total += num_fish;
    }

    return total;
}

fn run(filename: []const u8) !Answer {
    const file = try std.fs.cwd().openFile(filename, .{ .read = true });
    defer file.close();

    var reader = std.io.bufferedReader(file.reader()).reader();
    var buffer: [1024]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var buckets = [9]u64{ 0, 0, 0, 0, 0, 0, 0, 0, 0 };

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var tokens = std.mem.tokenize(u8, line, ",");
        while (tokens.next()) |timer| {
            buckets[try std.fmt.parseInt(usize, timer, 10)] += 1;
        }
    }

    return Answer{ .@"0" = solve(buckets, 80), .@"1" = solve(buckets, 256) };
}

pub fn main() !void {
    const answer = try run("inputs/" ++ @typeName(@This()) ++ ".txt");
    std.debug.print("{d}\n", .{answer.@"0"});
    std.debug.print("{d}\n", .{answer.@"1"});
}

test {
    const answer = try run("test-inputs/" ++ @typeName(@This()) ++ ".txt");
    try std.testing.expectEqual(answer.@"0", 5934);
    try std.testing.expectEqual(answer.@"1", 26984457539);
}
