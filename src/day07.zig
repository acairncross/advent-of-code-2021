const std = @import("std");
const Answer = struct { @"0": u32, @"1": u32 };

fn dist_lin(x: u32, y: u32) u32 {
    return if (x < y) y - x else x - y;
}

fn dist_quad(x: u32, y: u32) u32 {
    return dist_lin(x, y) * (dist_lin(x, y) + 1) / 2;
}

fn solve(positions: []u32, dist_fn: *const fn (u32, u32) u32) u32 {
    var min: u32 = positions[0];
    var max: u32 = positions[0];
    for (positions) |pos| {
        min = @minimum(pos, min);
        max = @maximum(pos, max);
    }

    var i: u32 = min;
    var min_fuel: ?u32 = null;
    while (i <= max) : (i += 1) {
        var fuel: u32 = 0;
        for (positions) |pos| {
            fuel += dist_fn.*(pos, i);
        }
        min_fuel = @minimum(min_fuel orelse fuel, fuel);
    }

    return min_fuel.?;
}

fn run(filename: []const u8) !Answer {
    const file = try std.fs.cwd().openFile(filename, .{ .read = true });
    defer file.close();

    var reader = std.io.bufferedReader(file.reader()).reader();
    var buffer: [4096]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var positions = std.ArrayList(u32).init(&gpa.allocator);
    defer positions.deinit();

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var tokens = std.mem.tokenize(u8, line, ",");
        while (tokens.next()) |pos| {
            try positions.append(try std.fmt.parseInt(u32, pos, 10));
        }
    }

    return Answer{ .@"0" = solve(positions.items, &dist_lin), .@"1" = solve(positions.items, &dist_quad) };
}

pub fn main() !void {
    const answer = try run("inputs/" ++ @typeName(@This()) ++ ".txt");
    std.debug.print("{d}\n", .{answer.@"0"});
    std.debug.print("{d}\n", .{answer.@"1"});
}

test {
    const answer = try run("test-inputs/" ++ @typeName(@This()) ++ ".txt");
    try std.testing.expectEqual(@as(u32, 37), answer.@"0");
    try std.testing.expectEqual(@as(u32, 168), answer.@"1");
}
