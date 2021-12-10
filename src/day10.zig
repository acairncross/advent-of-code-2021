const std = @import("std");
const Answer = struct { @"0": u32, @"1": u64 };

fn charCorruptionScore(c: u8) ?u32 {
    return switch (c) {
        ')' => 3,
        ']' => 57,
        '}' => 1197,
        '>' => 25137,
        else => null,
    };
}

fn charCompletionScore(c: u8) ?u32 {
    return switch (c) {
        ')' => 1,
        ']' => 2,
        '}' => 3,
        '>' => 4,
        else => null,
    };
}

fn isClosing(c: u8) bool {
    return switch (c) {
        ')', ']', '}', '>' => true,
        else => false,
    };
}

fn matchBracket(c: u8) ?u8 {
    return switch (c) {
        ')' => '(',
        ']' => '[',
        '}' => '{',
        '>' => '<',

        '(' => ')',
        '[' => ']',
        '{' => '}',
        '<' => '>',

        else => null,
    };
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

    var stack = std.ArrayList(u8).init(&gpa.allocator);
    defer stack.deinit();

    var total: u32 = 0;

    var scores = std.ArrayList(u64).init(&gpa.allocator);
    defer scores.deinit();

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        try stack.resize(line.len);
        var i: usize = 0;
        for (line) |c| {
            if (isClosing(c)) {
                if (stack.items[i - 1] == matchBracket(c).?) {
                    i -= 1;
                } else {
                    total += charCorruptionScore(c).?;
                    break;
                }
            } else {
                stack.items[i] = c;
                i += 1;
            }
        } else {
            var score: u64 = 0;
            while (i > 0) : (i -= 1) {
                score = 5 * score + charCompletionScore(matchBracket(stack.items[i - 1]).?).?;
            }
            try scores.append(score);
        }
    }

    std.sort.sort(u64, scores.items, {}, comptime std.sort.asc(u64));
    const middle_score = scores.items[scores.items.len / 2];

    return Answer{ .@"0" = total, .@"1" = middle_score };
}

pub fn main() !void {
    const answer = try run("inputs/" ++ @typeName(@This()) ++ ".txt");
    std.debug.print("{d}\n", .{answer.@"0"});
    std.debug.print("{d}\n", .{answer.@"1"});
}

test {
    const answer = try run("test-inputs/" ++ @typeName(@This()) ++ ".txt");
    try std.testing.expectEqual(@as(u32, 26397), answer.@"0");
    try std.testing.expectEqual(@as(u64, 288957), answer.@"1");
}
