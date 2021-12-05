const std = @import("std");
const Answer = struct { @"0": u32, @"1": u32 };
const V2 = [2]i32;
const LineSeg = [2]V2;

fn sign(x: i32) i32 {
    if (x > 0) {
        return 1;
    } else if (x < 0) {
        return -1;
    } else {
        return 0;
    }
}

// Direction of v from u
fn dirV2(u: V2, v: V2) V2 {
    return V2{ sign(v[0] - u[0]), sign(v[1] - u[1]) };
}

fn addV2(u: V2, v: V2) V2 {
    return V2{ u[0] + v[0], u[1] + v[1] };
}

fn eqV2(u: V2, v: V2) bool {
    return u[0] == v[0] and u[1] == v[1];
}

const Grid = struct {
    const Self = @This();

    items: []u32,
    dim: usize,
    allocator: *std.mem.Allocator,

    pub fn init(n: usize, allocator: *std.mem.Allocator) !Self {
        const items = try allocator.alloc(u32, n * n);
        std.mem.set(u32, items, 0);
        return Self{
            .items = items,
            .dim = n,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: Self) void {
        self.allocator.free(self.items);
    }

    pub fn ix(self: Self, row: usize, col: usize) *u32 {
        return &self.items[row * self.dim + col];
    }
};

fn solve(grid: Grid, vents: []LineSeg, count_diags: bool) u32 {
    for (vents) |line_seg| {
        const dir = dirV2(line_seg[0], line_seg[1]);
        if (dir[0] * dir[1] != 0 and !count_diags) {
            continue;
        }
        var pos = line_seg[0];

        grid.ix(@intCast(usize, pos[1]), @intCast(usize, pos[0])).* += 1;
        while (!eqV2(pos, line_seg[1])) {
            pos = addV2(pos, dir);
            grid.ix(@intCast(usize, pos[1]), @intCast(usize, pos[0])).* += 1;
        }
    }

    var num_multi_covers: u32 = 0;
    for (grid.items) |num_covers| {
        if (num_covers >= 2) {
            num_multi_covers += 1;
        }
    }

    return num_multi_covers;
}

fn run(filename: []const u8) !Answer {
    const file = try std.fs.cwd().openFile(filename, .{ .read = true });
    defer file.close();

    var reader = std.io.bufferedReader(file.reader()).reader();
    var buffer: [1024]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var vents = std.ArrayList(LineSeg).init(&gpa.allocator);
    defer vents.deinit();

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var endpoints = std.mem.tokenize(u8, line, " ->");

        var coords1 = std.mem.tokenize(u8, endpoints.next().?, ",");
        const x1 = try std.fmt.parseInt(i32, coords1.next().?, 10);
        const y1 = try std.fmt.parseInt(i32, coords1.next().?, 10);

        var coords2 = std.mem.tokenize(u8, endpoints.next().?, ",");
        const x2 = try std.fmt.parseInt(i32, coords2.next().?, 10);
        const y2 = try std.fmt.parseInt(i32, coords2.next().?, 10);

        try vents.append(LineSeg{ V2{ x1, y1 }, V2{ x2, y2 } });
    }

    var max_dim: usize = 0;
    for (vents.items) |line_seg| {
        max_dim = @maximum(max_dim, @intCast(usize, line_seg[0][0]));
        max_dim = @maximum(max_dim, @intCast(usize, line_seg[0][1]));
        max_dim = @maximum(max_dim, @intCast(usize, line_seg[1][0]));
        max_dim = @maximum(max_dim, @intCast(usize, line_seg[1][1]));
    }

    var grid1 = try Grid.init(max_dim + 1, &gpa.allocator);
    defer grid1.deinit();

    var grid2 = try Grid.init(max_dim + 1, &gpa.allocator);
    defer grid2.deinit();

    return Answer{ .@"0" = solve(grid1, vents.items, false), .@"1" = solve(grid2, vents.items, true) };
}

pub fn main() !void {
    const answer = try run("inputs/" ++ @typeName(@This()) ++ ".txt");
    std.debug.print("{d}\n", .{answer.@"0"});
    std.debug.print("{d}\n", .{answer.@"1"});
}

test {
    const answer = try run("test-inputs/" ++ @typeName(@This()) ++ ".txt");
    try std.testing.expectEqual(answer.@"0", 5);
    try std.testing.expectEqual(answer.@"1", 12);
}
