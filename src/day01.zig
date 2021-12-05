const std = @import("std");
const Answer = struct { @"0": u32, @"1": u32 };

fn count_num_increases(xs: []u32) u32 {
    var prev_opt: ?u32 = null;
    var num_increases: u32 = 0;

    for (xs) |cur| {
        if (prev_opt) |prev| {
            if (cur > prev) {
                num_increases += 1;
            }
        }
        prev_opt = cur;
    }

    return num_increases;
}

fn run(filename: []const u8) !Answer {
    const file = try std.fs.cwd().openFile(filename, .{ .read = true });
    defer file.close();

    var reader = std.io.bufferedReader(file.reader()).reader();
    var buffer: [1024]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var xs = std.ArrayList(u32).init(&gpa.allocator);
    defer xs.deinit();

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        try xs.append(try std.fmt.parseInt(u32, line, 10));
    }

    const num_increases = count_num_increases(xs.items);

    var xs3 = std.ArrayList(u32).init(&gpa.allocator);
    defer xs3.deinit();
    {
        var i: usize = 1;
        while (i < xs.items.len - 1) : (i += 1) {
            try xs3.append(xs.items[i - 1] + xs.items[i] + xs.items[i + 1]);
        }
    }

    const num_increases3 = count_num_increases(xs3.items);

    return Answer{ .@"0" = num_increases, .@"1" = num_increases3 };
}

pub fn main() !void {
    const answer = try run("inputs/" ++ @typeName(@This()) ++ ".txt");
    std.debug.print("{d}\n", .{answer.@"0"});
    std.debug.print("{d}\n", .{answer.@"1"});
}

test {
    const answer = try run("test-inputs/" ++ @typeName(@This()) ++ ".txt");
    try std.testing.expectEqual(answer.@"0", 7);
    try std.testing.expectEqual(answer.@"1", 5);
}
