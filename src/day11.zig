const std = @import("std");
const Answer = struct { @"0": u32, @"1": u32 };

const Point = struct { x: usize, y: usize };
const Neighbors = struct { items: [8]Point, len: usize };

fn displace(i: usize, ii: i32) i32 {
    return @intCast(i32, i) + ii;
}

const Grid = struct {
    const Self = @This();

    items: []u32,
    height: usize,
    width: usize,
    num_flashes: u32,
    step_num: u32,
    sync_flash: ?u32,
    allocator: *std.mem.Allocator,

    pub fn init(height: usize, width: usize, allocator: *std.mem.Allocator) !Self {
        const items = try allocator.alloc(u32, height * width);
        std.mem.set(u32, items, 0);
        return Self{
            .items = items,
            .height = height,
            .width = width,
            .num_flashes = 0,
            .step_num = 0,
            .sync_flash = null,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: Self) void {
        self.allocator.free(self.items);
    }

    pub fn ix(self: Self, row: usize, col: usize) *u32 {
        std.debug.assert(col < self.width);
        return &self.items[row * self.width + col];
    }

    pub fn step(self: *Self) void {
        var num_flashes_before = self.num_flashes;
        {
            var i: usize = 0;
            while (i < self.height) : (i += 1) {
                var j: usize = 0;
                while (j < self.width) : (j += 1) {
                    self.charge(i, j);
                }
            }
        }

        {
            var i: usize = 0;
            while (i < self.height) : (i += 1) {
                var j: usize = 0;
                while (j < self.width) : (j += 1) {
                    self.ix(i, j).* %= 10;
                }
            }
        }

        self.step_num += 1;

        var num_flashes_this_step = self.num_flashes - num_flashes_before;
        if (num_flashes_this_step == self.width * self.height) {
            self.sync_flash = self.sync_flash orelse self.step_num;
        }
    }

    pub fn charge(self: *Self, row: usize, col: usize) void {
        if (self.ix(row, col).* != 10) {
            self.ix(row, col).* += 1;
            if (self.ix(row, col).* == 10) {
                self.flash(row, col);
                self.num_flashes += 1;
            }
        }
    }

    pub fn flash(self: *Self, row: usize, col: usize) void {
        const neighbor_coords = self.neighbors(row, col);
        var i: usize = 0;
        while (i < neighbor_coords.len) : (i += 1) {
            self.charge(neighbor_coords.items[i].y, neighbor_coords.items[i].x);
        }
    }

    pub fn neighbors(self: Self, row: usize, col: usize) Neighbors {
        var num_neighbors: usize = 0;
        var neighbor_coords = [_]Point{undefined} ** 8;
        for ([_]i32{ -1, 0, 1 }) |i| {
            for ([_]i32{ -1, 0, 1 }) |j| {
                if (i == 0 and j == 0) {
                    continue;
                }
                if (self.in_bounds(displace(row, i), displace(col, j))) {
                    neighbor_coords[num_neighbors] = Point{ .x = @intCast(usize, displace(col, j)), .y = @intCast(usize, displace(row, i)) };
                    num_neighbors += 1;
                }
            }
        }
        return Neighbors{ .items = neighbor_coords, .len = num_neighbors };
    }

    pub fn in_bounds(self: Self, row: i32, col: i32) bool {
        return 0 <= row and @intCast(usize, row) < self.height and 0 <= col and @intCast(usize, col) < self.width;
    }
};

fn run(filename: []const u8) !Answer {
    const file = try std.fs.cwd().openFile(filename, .{ .read = true });
    defer file.close();

    var reader = std.io.bufferedReader(file.reader()).reader();
    var buffer: [4096]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var grid = try Grid.init(10, 10, &gpa.allocator);
    defer grid.deinit();

    try file.seekTo(0);
    var i: usize = 0;
    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| : (i += 1) {
        for (line) |c, j| {
            grid.ix(i, j).* = c - '0';
        }
    }

    i = 0;
    while (i < 100) : (i += 1) {
        grid.step();
    }

    const num_flashes = grid.num_flashes;

    while (grid.sync_flash == null) {
        grid.step();
    }

    return Answer{ .@"0" = num_flashes, .@"1" = grid.sync_flash.? };
}

pub fn main() !void {
    const answer = try run("inputs/" ++ @typeName(@This()) ++ ".txt");
    std.debug.print("{d}\n", .{answer.@"0"});
    std.debug.print("{d}\n", .{answer.@"1"});
}

test {
    const answer = try run("test-inputs/" ++ @typeName(@This()) ++ ".txt");
    try std.testing.expectEqual(@as(u32, 1656), answer.@"0");
    try std.testing.expectEqual(@as(u32, 195), answer.@"1");
}
