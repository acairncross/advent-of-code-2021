const std = @import("std");
const Answer = struct { @"0": u32, @"1": u32 };

const Point = struct { x: usize, y: usize };
const Neighbors = struct { items: [8]Point, len: usize };

const PathMap = std.StringHashMap(std.ArrayList([]const u8));

fn isSmall(name: []const u8) bool {
    return std.ascii.isLower(name[0]);
}

fn addPath(paths: *PathMap, from: []const u8, to: []const u8, arena: *std.heap.ArenaAllocator) !void {
    if (paths.getPtr(from)) |tos| {
        try tos.append(to);
    } else {
        var tos = std.ArrayList([]const u8).init(&arena.allocator);
        try tos.append(to);
        try paths.put(from, tos);
    }
}

fn countPaths(paths: PathMap, from: []const u8, to: []const u8, visited: *std.StringHashMap(u32), allow_revisits: bool) error{OutOfMemory}!u32 {
    if (std.mem.eql(u8, from, to)) {
        return 1;
    } else {
        var max_visited_count: u32 = 0;
        var it = visited.valueIterator();
        while (it.next()) |visited_count| {
            max_visited_count = @maximum(visited_count.*, max_visited_count);
        }

        var num_paths: u32 = 0;
        for (paths.get(from).?.items) |to_next| {
            const valid_next = !isSmall(to_next) or if (allow_revisits) (visited.get(to_next).? == 0 or (max_visited_count < 2 and !std.mem.eql(u8, "start", to_next))) else (visited.get(to_next).? == 0);
            if (valid_next) {
                if (isSmall(to_next)) {
                    visited.getPtr(to_next).?.* += 1;
                }
                num_paths += try countPaths(paths, to_next, to, visited, allow_revisits);
                if (isSmall(to_next)) {
                    visited.getPtr(to_next).?.* -= 1;
                }
            }
        }
        return num_paths;
    }
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

    var node_names = std.StringHashMap(void).init(&arena.allocator);
    var paths = std.StringHashMap(std.ArrayList([]const u8)).init(&arena.allocator);

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var tokens = std.mem.tokenize(u8, line, "-");

        const from = tokens.next().?;
        try node_names.put(try arena.allocator.dupe(u8, from), undefined);

        const to = tokens.next().?;
        try node_names.put(try arena.allocator.dupe(u8, to), undefined);

        try addPath(&paths, node_names.getKey(from).?, node_names.getKey(to).?, &arena);
        try addPath(&paths, node_names.getKey(to).?, node_names.getKey(from).?, &arena);
    }

    var visited = std.StringHashMap(u32).init(&arena.allocator);
    var it = node_names.keyIterator();
    while (it.next()) |key| {
        if (std.mem.eql(u8, key.*, "start")) {
            try visited.put(key.*, 1);
        } else {
            try visited.put(key.*, 0);
        }
    }

    const num_paths1 = try countPaths(paths, node_names.getKey("start").?, node_names.getKey("end").?, &visited, false);
    const num_paths2 = try countPaths(paths, node_names.getKey("start").?, node_names.getKey("end").?, &visited, true);

    return Answer{ .@"0" = num_paths1, .@"1" = num_paths2 };
}

pub fn main() !void {
    const answer = try run("inputs/" ++ @typeName(@This()) ++ ".txt");
    std.debug.print("{d}\n", .{answer.@"0"});
    std.debug.print("{d}\n", .{answer.@"1"});
}

test {
    const answer = try run("test-inputs/" ++ @typeName(@This()) ++ ".txt");
    try std.testing.expectEqual(@as(u32, 10), answer.@"0");
    try std.testing.expectEqual(@as(u32, 36), answer.@"1");
}
