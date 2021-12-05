const std = @import("std");
const Answer = struct { @"0": u32, @"1": u32 };

const BingoBoard = struct {
    const Self = @This();

    numbers: []u32,
    marks: []bool,
    dim: usize,
    allocator: *std.mem.Allocator,

    pub fn init(n: usize, allocator: *std.mem.Allocator) !Self {
        const numbers = try allocator.alloc(u32, n * n);
        const marks = try allocator.alloc(bool, n * n);
        var i: usize = 0;
        while (i < marks.len) : (i += 1) {
            marks[i] = false;
        }
        return Self{
            .numbers = numbers,
            .marks = marks,
            .dim = n,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: Self) void {
        self.allocator.free(self.numbers);
        self.allocator.free(self.marks);
    }

    pub fn ix(self: Self, row: usize, col: usize) *u32 {
        return &self.numbers[row * self.dim + col];
    }

    pub fn mark_ix(self: Self, row: usize, col: usize) *bool {
        return &self.marks[row * self.dim + col];
    }

    pub fn mark(self: Self, val: u32) void {
        for (self.numbers) |number, idx| {
            if (number == val) {
                self.marks[idx] = true;
            }
        }
    }

    pub fn unmark_all(self: Self) void {
        var i: usize = 0;
        while (i < self.marks.len) : (i += 1) {
            self.marks[i] = false;
        }
    }

    pub fn has_won(self: Self) bool {
        {
            var i: usize = 0;
            while (i < self.dim) : (i += 1) {
                // Horizontal
                {
                    var j: usize = 0;
                    while (j < self.dim) : (j += 1) {
                        if (!self.marks[i * self.dim + j]) {
                            break;
                        }
                    } else {
                        return true;
                    }
                }

                // Vertical
                {
                    var j: usize = 0;
                    while (j < self.dim) : (j += 1) {
                        if (!self.marks[j * self.dim + i]) {
                            break;
                        }
                    } else {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    pub fn eval_score(self: Self, last_draw: u32) u32 {
        var score: u32 = 0;
        for (self.numbers) |number, i| {
            if (!self.marks[i]) {
                score += number;
            }
        }
        score *= last_draw;
        return score;
    }
};

fn run(filename: []const u8) !Answer {
    const file = try std.fs.cwd().openFile(filename, .{ .read = true });
    defer file.close();

    var reader = std.io.bufferedReader(file.reader()).reader();
    var buffer: [1024]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var drawn_numbers = std.ArrayList(u32).init(&gpa.allocator);
    defer drawn_numbers.deinit();

    {
        const line0 = (try reader.readUntilDelimiterOrEof(&buffer, '\n')).?;
        var line0_tokens = std.mem.tokenize(u8, line0, ",");
        while (line0_tokens.next()) |token| {
            try drawn_numbers.append(try std.fmt.parseInt(u32, token, 10));
        }
    }

    var boards = std.ArrayList(BingoBoard).init(&gpa.allocator);
    defer boards.deinit();

    {
        while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |empty_line| {
            std.debug.assert(empty_line.len == 0);
            var i: usize = 0;
            var board = try BingoBoard.init(5, &gpa.allocator);
            while (i < 5) : (i += 1) {
                const line = (try reader.readUntilDelimiterOrEof(&buffer, '\n')).?;
                var tokens = std.mem.tokenize(u8, line, " ");
                var j: usize = 0;
                while (tokens.next()) |token| : (j += 1) {
                    const number = try std.fmt.parseInt(u32, token, 10);
                    board.ix(i, j).* = number;
                }
            }
            try boards.append(board);
        }
    }

    // Part 1
    var first_win_draw_idx: usize = drawn_numbers.items.len;
    var first_win_board_idx: usize = undefined;

    // Part 2
    var last_win_draw_idx: usize = 0;
    var last_win_board_idx: usize = undefined;

    for (boards.items) |board, bi| {
        for (drawn_numbers.items) |number, ni| {
            board.mark(number);
            if (board.has_won()) {
                if (ni < first_win_draw_idx) {
                    first_win_draw_idx = ni;
                    first_win_board_idx = bi;
                }
                if (ni > last_win_draw_idx) {
                    last_win_draw_idx = ni;
                    last_win_board_idx = bi;
                }
                break;
            }
        }
    }
    const score1 = boards.items[first_win_board_idx].eval_score(drawn_numbers.items[first_win_draw_idx]);
    const score2: u32 = boards.items[last_win_board_idx].eval_score(drawn_numbers.items[last_win_draw_idx]);

    for (boards.items) |board| {
        board.deinit();
    }

    return Answer{ .@"0" = score1, .@"1" = score2 };
}

pub fn main() !void {
    const answer = try run("inputs/" ++ @typeName(@This()) ++ ".txt");
    std.debug.print("{d}\n", .{answer.@"0"});
    std.debug.print("{d}\n", .{answer.@"1"});
}

test {
    const answer = try run("test-inputs/" ++ @typeName(@This()) ++ ".txt");
    try std.testing.expectEqual(answer.@"0", 4512);
    try std.testing.expectEqual(answer.@"1", 1924);
}
