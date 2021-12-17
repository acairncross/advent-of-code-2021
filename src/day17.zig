const std = @import("std");
const Answer = struct { @"0": u32, @"1": u32 };

const Range = struct { lo: i32, hi: i32 };
const Target = struct { x: Range, y: Range };

fn in_range(x: i32, range: Range) bool {
    return range.lo <= x and x <= range.hi;
}

fn in_target(y: i32, x: i32, target: Target) bool {
    return in_range(y, target.y) and in_range(x, target.x);
}

fn simulate(yv_: i32, xv_: i32, target: Target) bool {
    var step_num: usize = 0;
    var yv = yv_;
    var xv = xv_;
    var y: i32 = 0;
    var x: i32 = 0;
    while (true) : (step_num += 1) {
        y += yv;
        x += xv;
        if (in_target(y, x, target)) {
            return true;
        } else if (y < target.y.lo or x > target.x.hi) {
            return false;
        }

        yv -= 1;
        if (xv > 0) {
            xv -= 1;
        } else if (xv < 0) {
            xv += 1;
        }
    }
}

fn run(filename: []const u8) !Answer {
    const file = try std.fs.cwd().openFile(filename, .{ .read = true });
    defer file.close();

    var reader = std.io.bufferedReader(file.reader()).reader();
    var buffer: [4096]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var target: Target = undefined;

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var tokens = std.mem.tokenize(u8, line, "=,. ");
        _ = tokens.next().?; // target
        _ = tokens.next().?; // area
        _ = tokens.next().?; // x
        const x_lo = try std.fmt.parseInt(i32, tokens.next().?, 10);
        const x_hi = try std.fmt.parseInt(i32, tokens.next().?, 10);
        const x_range = Range{ .lo = x_lo, .hi = x_hi };
        _ = tokens.next().?; // y
        const y_lo = try std.fmt.parseInt(i32, tokens.next().?, 10);
        const y_hi = try std.fmt.parseInt(i32, tokens.next().?, 10);
        const y_range = Range{ .lo = y_lo, .hi = y_hi };

        target = Target{ .x = x_range, .y = y_range };
    }

    std.debug.assert(target.x.lo > 0);
    std.debug.assert(target.y.hi < 0);

    var counter: u32 = 0;
    var max_yv: i32 = 0;
    {
        var yv: i32 = target.y.lo;
        while (yv < -target.y.lo) : (yv += 1) {
            var xv: i32 = 0;
            while (xv <= target.x.hi) : (xv += 1) {
                if (simulate(yv, xv, target)) {
                    max_yv = @maximum(yv, max_yv);
                    counter += 1;
                }
            }
        }
    }

    std.debug.assert(max_yv > 0);
    const max_y = @intCast(u32, max_yv) * (@intCast(u32, max_yv) + 1) / 2;

    return Answer{ .@"0" = max_y, .@"1" = counter };
}

pub fn main() !void {
    const answer = try run("inputs/" ++ @typeName(@This()) ++ ".txt");
    std.debug.print("{d}\n", .{answer.@"0"});
    std.debug.print("{d}\n", .{answer.@"1"});
}

test {
    const answer = try run("test-inputs/" ++ @typeName(@This()) ++ ".txt");
    try std.testing.expectEqual(answer.@"0", 45);
    try std.testing.expectEqual(answer.@"1", 112);
}
