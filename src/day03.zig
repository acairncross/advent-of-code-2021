const std = @import("std");
const Answer = struct { @"0": u32, @"1": u32 };

fn count_candidates(candidates: []bool) u32 {
    var n: u32 = 0;
    for (candidates) |candidate| {
        if (candidate) {
            n += 1;
        }
    }
    return n;
}

fn find_candidate(candidates: []bool) ?usize {
    for (candidates) |candidate, i| {
        if (candidate) {
            return i;
        }
    }
    return null;
}

fn find_rating(report: []u32, bitwidth: usize, oxy_criterion: bool, allocator: *std.mem.Allocator) !u32 {
    var candidates = std.ArrayList(bool).init(allocator);
    for (report) |_| {
        try candidates.append(true);
    }
    defer candidates.deinit();

    var i: u32 = 0;
    while (count_candidates(candidates.items) > 1) : (i += 1) {
        const j = bitwidth - i - 1;

        var num_ones: u32 = 0;
        for (report) |n, ni| {
            if (n & (1 <<| j) > 0 and candidates.items[ni]) {
                num_ones += 1;
            }
        }
        const num_candidates = count_candidates(candidates.items);
        const keepbit: u32 =
            if ((oxy_criterion and 2 * num_ones >= num_candidates) or (!oxy_criterion and 2 * num_ones < num_candidates)) 1 else 0;

        for (report) |n, ni| {
            if ((n & (1 <<| j)) >> @intCast(u6, j) != keepbit) {
                candidates.items[ni] = false;
            }
        }
    }

    return report[find_candidate(candidates.items).?];
}

fn run(filename: []const u8) !Answer {
    const file = try std.fs.cwd().openFile(filename, .{ .read = true });
    defer file.close();

    var reader = std.io.bufferedReader(file.reader()).reader();
    var buffer: [1024]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var report = std.ArrayList(u32).init(&gpa.allocator);
    defer report.deinit();

    var bitwidth: usize = undefined;

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        bitwidth = line.len;
        try report.append(try std.fmt.parseInt(u32, line, 2));
    }

    // Part 1
    var gamma_rate: u32 = 0;
    {
        var i: u32 = 0;
        while (i < bitwidth) : (i += 1) {
            var num_ones: u32 = 0;
            for (report.items) |n| {
                if (n & (1 <<| i) > 0) {
                    num_ones += 1;
                }
            }
            if (2 * num_ones > report.items.len) {
                gamma_rate |= 1 <<| i;
            }
        }
    }
    const epsilon_rate: u32 = ((1 <<| @intCast(u32, bitwidth)) - 1) & ~gamma_rate;

    // Part 2
    const oxygen_rating = try find_rating(report.items, bitwidth, true, &gpa.allocator);
    const co2_rating = try find_rating(report.items, bitwidth, false, &gpa.allocator);

    return Answer{ .@"0" = gamma_rate * epsilon_rate, .@"1" = oxygen_rating * co2_rating };
}

pub fn main() !void {
    const answer = try run("inputs/" ++ @typeName(@This()) ++ ".txt");
    std.debug.print("{d}\n", .{answer.@"0"});
    std.debug.print("{d}\n", .{answer.@"1"});
}

test {
    const answer = try run("test-inputs/" ++ @typeName(@This()) ++ ".txt");
    try std.testing.expect(answer.@"0" == 198);
    try std.testing.expect(answer.@"1" == 230);
}
