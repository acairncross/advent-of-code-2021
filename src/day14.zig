const std = @import("std");
const Answer = struct { @"0": u64, @"1": u64 };

const Counts = std.AutoHashMap(u8, u64);

fn applyRulesAndCount(template: std.ArrayList(u8), iterated_rules: std.StringHashMap(Counts), counts: *Counts) !void {
    var i: usize = 0;
    while (i < template.items.len - 1) : (i += 1) {
        try addCounts(iterated_rules.get(template.items[i .. i + 2]).?, counts);
        if (i == 0 or i == template.items.len - 2) {
            if (counts.get(template.items[i])) |count| {
                try counts.put(template.items[i], count - 1);
            }
        }
    }
}

fn most_extreme(counts: Counts, max_not_min: bool) ?u64 {
    var it = counts.valueIterator();
    var extremum: ?u64 = null;
    while (it.next()) |count| {
        extremum = if (max_not_min) @maximum(extremum orelse count.*, count.*) else @minimum(extremum orelse count.*, count.*);
    }
    return extremum;
}

fn addCounts(x: Counts, y: *Counts) !void {
    var it = x.iterator();
    while (it.next()) |entry| {
        if (y.get(entry.key_ptr.*)) |value| {
            try y.put(entry.key_ptr.*, entry.value_ptr.* + value);
        } else {
            try y.put(entry.key_ptr.*, entry.value_ptr.*);
        }
    }
}

fn step(iterated_rules: std.StringHashMap(Counts), iterated_rules_next: *std.StringHashMap(Counts), rules: std.StringHashMap(u8), arena: *std.heap.ArenaAllocator) !void {
    var it = rules.iterator();
    while (it.next()) |entry| {
        const production: u8 = entry.value_ptr.*;
        const left = [2]u8{ (entry.key_ptr.*)[0], production };
        const right = [2]u8{ production, (entry.key_ptr.*)[1] };

        var counts = Counts.init(&arena.allocator);
        try addCounts(iterated_rules.get(left[0..2]).?, &counts);
        try addCounts(iterated_rules.get(right[0..2]).?, &counts);
        if (counts.get(production)) |count| {
            try counts.put(production, count - 1);
        }

        try iterated_rules_next.put(entry.key_ptr.*, counts);
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

    var template = std.ArrayList(u8).init(&gpa.allocator);
    defer template.deinit();

    var rules = std.StringHashMap(u8).init(&arena.allocator);
    var iterated_rules = std.StringHashMap(Counts).init(&arena.allocator);
    var iterated_rules_next = std.StringHashMap(Counts).init(&arena.allocator);

    if (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        try template.resize(line.len);
        std.mem.copy(u8, template.items, line);
    }

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        if (line.len == 0) {
            continue;
        }

        var tokens = std.mem.tokenize(u8, line, " >-");
        const lhs = try arena.allocator.dupe(u8, tokens.next().?);
        const rhs = tokens.next().?[0];

        try rules.put(lhs, rhs);
        var counts = Counts.init(&arena.allocator);
        if (lhs[0] == lhs[1]) {
            try counts.put(lhs[0], 2);
        } else {
            try counts.put(lhs[0], 1);
            try counts.put(lhs[1], 1);
        }
        try iterated_rules.put(lhs, counts);
    }

    var i: usize = 0;
    while (i < 10) : (i += 1) {
        try step(iterated_rules, &iterated_rules_next, rules, &arena);
        std.mem.swap(std.StringHashMap(Counts), &iterated_rules, &iterated_rules_next);
        iterated_rules_next.clearRetainingCapacity();
    }
    var counts = Counts.init(&arena.allocator);
    try applyRulesAndCount(template, iterated_rules, &counts);
    const answer1 = most_extreme(counts, true).? - most_extreme(counts, false).?;

    while (i < 40) : (i += 1) {
        try step(iterated_rules, &iterated_rules_next, rules, &arena);
        std.mem.swap(std.StringHashMap(Counts), &iterated_rules, &iterated_rules_next);
        iterated_rules_next.clearRetainingCapacity();
    }
    counts.clearRetainingCapacity();
    try applyRulesAndCount(template, iterated_rules, &counts);
    const answer2 = most_extreme(counts, true).? - most_extreme(counts, false).?;

    return Answer{ .@"0" = answer1, .@"1" = answer2 };
}

pub fn main() !void {
    const answer = try run("inputs/" ++ @typeName(@This()) ++ ".txt");
    std.debug.print("{d}\n", .{answer.@"0"});
    std.debug.print("{d}\n", .{answer.@"1"});
}

test {
    const answer = try run("test-inputs/" ++ @typeName(@This()) ++ ".txt");
    try std.testing.expectEqual(answer.@"0", 1588);
    try std.testing.expectEqual(answer.@"1", 2188189693529);
}
