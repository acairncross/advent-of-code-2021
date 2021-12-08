const std = @import("std");
const Answer = struct { @"0": u32, @"1": u32 };

const Digit = std.bit_set.IntegerBitSet(7);
const ObservedDigits = [10]Digit;
const OutputDigits = [4]Digit;

const zero = Digit{ .mask = 0b1110111 };
const one = Digit{ .mask = 0b0100100 };
const two = Digit{ .mask = 0b1011101 };
const three = Digit{ .mask = 0b1101101 };
const four = Digit{ .mask = 0b0101110 };
const five = Digit{ .mask = 0b1101011 };
const six = Digit{ .mask = 0b1111011 };
const seven = Digit{ .mask = 0b0100101 };
const eight = Digit{ .mask = 0b1111111 };
const nine = Digit{ .mask = 0b1101111 };

const all_digits = [_]Digit{ zero, one, two, three, four, five, six, seven, eight, nine };

fn intersect(x: Digit, y: Digit) Digit {
    var z = Digit.initEmpty();
    var i: usize = 0;
    while (i < Digit.bit_length) : (i += 1) {
        if (x.isSet(i) and y.isSet(i)) {
            z.set(i);
        }
    }
    return z;
}

fn onion(x: Digit, y: Digit) Digit {
    var z = x;
    var i: usize = 0;
    while (i < Digit.bit_length) : (i += 1) {
        if (y.isSet(i)) {
            z.set(i);
        }
    }
    return z;
}

fn minus(x: Digit, y: Digit) Digit {
    var z = x;
    var i: usize = 0;
    while (i < Digit.bit_length) : (i += 1) {
        if (y.isSet(i)) {
            z.unset(i);
        }
    }
    return z;
}

fn subset(x: Digit, y: Digit) bool {
    var i: usize = 0;
    while (i < Digit.bit_length) : (i += 1) {
        if (!x.isSet(i) and y.isSet(i)) {
            return false;
        }
    }
    return true;
}

fn equal(x: Digit, y: Digit) bool {
    var i: usize = 0;
    while (i < Digit.bit_length) : (i += 1) {
        if (x.isSet(i) != y.isSet(i)) {
            return false;
        }
    }
    return true;
}

// Produces much garbage
fn permutations(n: usize, allocator: *std.mem.Allocator) error{OutOfMemory}!std.ArrayList(std.ArrayList(usize)) {
    if (n == 0) {
        var perms = std.ArrayList(std.ArrayList(usize)).init(allocator);
        try perms.append(std.ArrayList(usize).init(allocator));
        return perms;
    } else {
        var rec_perms = try permutations(n - 1, allocator);
        var perms = std.ArrayList(std.ArrayList(usize)).init(allocator);
        for (rec_perms.items) |rec_perm| {
            var i: usize = 0;
            while (i <= rec_perm.items.len) : (i += 1) {
                var perm = std.ArrayList(usize).init(allocator);
                try perm.resize(n - 1);
                std.mem.copy(usize, perm.items, rec_perm.items);

                try perm.insert(i, n - 1);
                try perms.append(perm);
            }
        }
        return perms;
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

    var observed_digits = std.ArrayList(ObservedDigits).init(&arena.allocator);
    var output_digits = std.ArrayList(OutputDigits).init(&arena.allocator);

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var observed_and_output_tokens = std.mem.tokenize(u8, line, "|");

        var observed_tokens = std.mem.tokenize(u8, observed_and_output_tokens.next().?, " ");
        {
            var i: usize = 0;
            var digits: ObservedDigits = undefined;
            while (observed_tokens.next()) |token| : (i += 1) {
                var digit = Digit.initEmpty();
                for (token) |c| {
                    digit.set(@as(usize, c - 'a'));
                }
                digits[i] = digit;
            }
            try observed_digits.append(digits);
        }

        var output_tokens = std.mem.tokenize(u8, observed_and_output_tokens.next().?, " ");
        {
            var i: usize = 0;
            var digits: OutputDigits = undefined;
            while (output_tokens.next()) |token| : (i += 1) {
                var digit = Digit.initEmpty();
                for (token) |c| {
                    digit.set(@as(usize, c - 'a'));
                }
                digits[i] = digit;
            }
            try output_digits.append(digits);
        }
    }

    var total: u32 = 0;
    for (output_digits.items) |digits| {
        for (digits) |digit| {
            switch (digit.count()) {
                // Digits 1, 7, 4, or 8 have this many segments
                2, 3, 4, 7 => {
                    total += 1;
                },
                else => {},
            }
        }
    }

    const perms = try permutations(Digit.bit_length, &arena.allocator);
    var grand_total: u32 = 0;

    {
        var i: usize = 0;
        while (i < output_digits.items.len) : (i += 1) {
            var num_valid_perms: u32 = 0;
            for (perms.items) |perm| {
                outer: for (observed_digits.items[i]) |digit| {
                    var permuted_digit = Digit.initEmpty();
                    var j: usize = 0;
                    while (j < Digit.bit_length) : (j += 1) {
                        if (digit.isSet(j)) {
                            permuted_digit.set(perm.items[j]);
                        }
                    }
                    j = 0;
                    while (j < 10) : (j += 1) {
                        if (equal(permuted_digit, all_digits[j])) {
                            break;
                        }
                    } else {
                        // Not equal to any of the digits
                        break :outer;
                    }
                } else {
                    // Found the correct permutation
                    num_valid_perms += 1;

                    for (output_digits.items[i]) |digit, digit_i| {
                        var permuted_digit = Digit.initEmpty();
                        var j: usize = 0;
                        while (j < Digit.bit_length) : (j += 1) {
                            if (digit.isSet(j)) {
                                permuted_digit.set(perm.items[j]);
                            }
                        }
                        j = 0;
                        const pow10 = [_]u32{ 1000, 100, 10, 1 };
                        while (j < 10) : (j += 1) {
                            if (equal(permuted_digit, all_digits[j])) {
                                grand_total += pow10[digit_i] * @intCast(u32, j);
                                break;
                            }
                        } else {
                            unreachable();
                        }
                    }
                }
            }
        }
    }

    return Answer{ .@"0" = total, .@"1" = grand_total };
}

pub fn main() !void {
    const answer = try run("inputs/" ++ @typeName(@This()) ++ ".txt");
    std.debug.print("{d}\n", .{answer.@"0"});
    std.debug.print("{d}\n", .{answer.@"1"});
}

test {
    const answer = try run("test-inputs/" ++ @typeName(@This()) ++ ".txt");
    try std.testing.expectEqual(@as(u32, 26), answer.@"0");
    try std.testing.expectEqual(@as(u32, 61229), answer.@"1");
}
