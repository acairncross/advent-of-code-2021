const std = @import("std");
const Answer = struct { @"0": u32 };
const Point = struct { x: usize, y: usize };

const Variable = enum { X, Y };
const Equality = struct { variable: Variable, value: usize };

const Grid = struct {
    const Self = @This();

    items: []u8,

    height: usize,
    width: usize,

    buffer_height: usize,
    buffer_width: usize,

    allocator: *std.mem.Allocator,

    pub fn init(height: usize, width: usize, allocator: *std.mem.Allocator) !Self {
        const items = try allocator.alloc(u8, height * width);
        std.mem.set(u8, items, '.');
        return Self{
            .items = items,
            .height = height,
            .width = width,
            .buffer_height = height,
            .buffer_width = width,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: Self) void {
        self.allocator.free(self.items);
    }

    pub fn ix(self: Self, row: usize, col: usize) *u8 {
        std.debug.assert(col < self.width);
        return &self.items[row * self.buffer_width + col];
    }

    pub fn count(self: Self) u32 {
        var total: u32 = 0;
        var i: usize = 0;
        while (i < self.height) : (i += 1) {
            var j: usize = 0;
            while (j < self.width) : (j += 1) {
                if (self.ix(i, j).* == '#') {
                    total += 1;
                }
            }
        }
        return total;
    }

    pub fn fold(self: *Self, constraint: Equality) void {
        var i: usize = 0;
        while (i < self.height) : (i += 1) {
            var j: usize = 0;
            while (j < self.width) : (j += 1) {
                if (self.ix(i, j).* == '#') {
                    switch (constraint.variable) {
                        .X => {
                            if (j > constraint.value) {
                                self.ix(i, constraint.value - (j - constraint.value)).* = '#';
                                self.ix(i, j).* = '.';
                            }
                        },
                        .Y => {
                            if (i > constraint.value) {
                                self.ix(constraint.value - (i - constraint.value), j).* = '#';
                                self.ix(i, j).* = '.';
                            }
                        },
                    }
                }
            }
        }
        switch (constraint.variable) {
            .X => {
                self.width = constraint.value;
            },
            .Y => {
                self.height = constraint.value;
            },
        }
    }
};

fn run(filename: []const u8) !Answer {
    const file = try std.fs.cwd().openFile(filename, .{ .read = true });
    defer file.close();

    var reader = std.io.bufferedReader(file.reader()).reader();
    var buffer: [1024]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var coords = std.ArrayList(Point).init(&gpa.allocator);
    defer coords.deinit();

    var folds = std.ArrayList(Equality).init(&gpa.allocator);
    defer folds.deinit();

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        if (line.len == 0) {
            break;
        }
        var tokens = std.mem.tokenize(u8, line, ",");
        const x = try std.fmt.parseInt(usize, tokens.next().?, 10);
        const y = try std.fmt.parseInt(usize, tokens.next().?, 10);

        try coords.append(Point{ .x = x, .y = y });
    }

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var i: usize = 0;
        while (line[i] != 'x' and line[i] != 'y') : (i += 1) {}
        const variable = line[i];
        while (!std.ascii.isDigit(line[i])) : (i += 1) {}
        try folds.append(switch (variable) {
            'x' => Equality{ .variable = .X, .value = try std.fmt.parseInt(usize, line[i..], 10) },
            'y' => Equality{ .variable = .Y, .value = try std.fmt.parseInt(usize, line[i..], 10) },
            else => unreachable,
        });
    }

    var max_y: usize = 0;
    var max_x: usize = 0;
    for (coords.items) |coord| {
        max_y = @maximum(max_y, @intCast(usize, coord.y));
        max_x = @maximum(max_x, @intCast(usize, coord.x));
    }

    var grid = try Grid.init(max_y + 1, max_x + 1, &gpa.allocator);
    defer grid.deinit();

    for (coords.items) |coord| {
        grid.ix(coord.y, coord.x).* = '#';
    }

    grid.fold(folds.items[0]);
    const answer = Answer{ .@"0" = grid.count() };

    for (folds.items[1..]) |fold| {
        grid.fold(fold);
    }
    var i: usize = 0;
    while (i < grid.height) : (i += 1) {
        std.debug.print("{s}\n", .{grid.items[i * grid.buffer_width .. i * grid.buffer_width + grid.width]});
    }

    return answer;
}

pub fn main() !void {
    const answer = try run("inputs/" ++ @typeName(@This()) ++ ".txt");
    std.debug.print("{d}\n", .{answer.@"0"});
}

test {
    const answer = try run("test-inputs/" ++ @typeName(@This()) ++ ".txt");
    try std.testing.expectEqual(answer.@"0", 17);
}
