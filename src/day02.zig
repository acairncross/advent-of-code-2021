const std = @import("std");
const Answer = struct { @"0": i32, @"1": i32 };

fn run(filename: []const u8) !Answer {
    const file = try std.fs.cwd().openFile(filename, .{ .read = true });
    defer file.close();

    var reader = std.io.bufferedReader(file.reader()).reader();
    var buffer: [1024]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var horiz_pos: i32 = 0;
    var aim: i32 = 0;

    var depth_1: i32 = 0;
    var depth_2: i32 = 0;

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var tokens = std.mem.tokenize(u8, line, " ");
        const dir = tokens.next().?;
        const mag = try std.fmt.parseInt(i32, tokens.next().?, 10);

        if (std.mem.eql(u8, dir, "forward")) {
            horiz_pos += mag;
            depth_2 += aim * mag;
        } else if (std.mem.eql(u8, dir, "down")) {
            depth_1 += mag;
            aim += mag;
        } else if (std.mem.eql(u8, dir, "up")) {
            depth_1 -= mag;
            aim -= mag;
        } else {
            unreachable;
        }
    }

    return Answer{ .@"0" = horiz_pos * depth_1, .@"1" = horiz_pos * depth_2 };
}

pub fn main() !void {
    const answer = try run("inputs/" ++ @typeName(@This()) ++ ".txt");
    std.debug.print("{d}\n", .{answer.@"0"});
    std.debug.print("{d}\n", .{answer.@"1"});
}

test {
    const answer = try run("test-inputs/" ++ @typeName(@This()) ++ ".txt");
    try std.testing.expect(answer.@"0" == 150);
    try std.testing.expect(answer.@"1" == 900);
}
