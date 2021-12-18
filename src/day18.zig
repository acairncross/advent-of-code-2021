const std = @import("std");
const Answer = struct { @"0": u32, @"1": u32 };

const NumberTag = enum {
    regular_num,
    pair_num,
};

const Number = union(NumberTag) {
    regular_num: *ValueNode,
    pair_num: Pair,
};

const Pair = struct { left: *Number, right: *Number };

const ValueNode = struct {
    value: u32,
    prev: ?*ValueNode,
    next: ?*ValueNode,
};

fn parseNumber(str: []const u8, idx: *usize, arena: *std.heap.ArenaAllocator) error{ Overflow, InvalidCharacter, OutOfMemory }!*Number {
    const b = str[idx.*];
    idx.* += 1;
    if (b == '[') {
        const left = try parseNumber(str, idx, arena);
        idx.* += 1;
        const right = try parseNumber(str, idx, arena);
        idx.* += 1; // close bracket
        var num = try arena.allocator.create(Number);
        num.* = Number{ .pair_num = Pair{ .left = left, .right = right } };
        return num;
    } else {
        var num = try arena.allocator.create(Number);
        var node = try arena.allocator.create(ValueNode);
        node.* = ValueNode{
            .value = try std.fmt.parseInt(u32, ([1]u8{b})[0..], 10),
            .prev = null,
            .next = null,
        };
        num.* = Number{
            .regular_num = node,
        };
        return num;
    }
}

fn printNumber(num: Number) void {
    switch (num) {
        NumberTag.regular_num => |n| {
            std.debug.print("{d}", .{n});
        },
        NumberTag.pair_num => |pair| {
            std.debug.print("[", .{});
            printNumber(pair.left.*);
            std.debug.print(",", .{});
            printNumber(pair.right.*);
            std.debug.print("]", .{});
        },
    }
}

fn flattenToValues(num: Number, arr: *std.ArrayList(u32)) error{OutOfMemory}!void {
    switch (num) {
        NumberTag.regular_num => |n| {
            try arr.append(n.*.value);
        },
        NumberTag.pair_num => |pair| {
            try flattenToValues(pair.left.*, arr);
            try flattenToValues(pair.right.*, arr);
        },
    }
}

fn flattenNumber(num: Number, depth: u32, arr: *std.ArrayList(*ValueNode)) error{OutOfMemory}!void {
    switch (num) {
        NumberTag.regular_num => |node| {
            try arr.append(node);
        },
        NumberTag.pair_num => |pair| {
            try flattenNumber(pair.left.*, depth + 1, arr);
            try flattenNumber(pair.right.*, depth + 1, arr);
        },
    }
}

fn mergeNumbers(left: *Number, right: *Number, arena: *std.heap.ArenaAllocator) !*Number {
    var z = try arena.allocator.create(Number);
    z.* = Number{
        .pair_num = Pair{
            .left = left,
            .right = right,
        },
    };
    var left_last = last(left.*).?;
    var right_head = head(right.*).?;
    left_last.*.next = right_head;
    right_head.*.prev = left_last;
    return z;
}

fn head(num_root: Number) ?*ValueNode {
    var num = num_root;
    while (true) {
        switch (num) {
            NumberTag.regular_num => |node| {
                return node;
            },
            NumberTag.pair_num => |pair| {
                num = pair.left.*;
            },
        }
    }
}

fn last(num_root: Number) ?*ValueNode {
    var num = num_root;
    while (true) {
        switch (num) {
            NumberTag.regular_num => |node| {
                return node;
            },
            NumberTag.pair_num => |pair| {
                num = pair.right.*;
            },
        }
    }
}

fn explode(num: *Number, depth: u32, arena: *std.heap.ArenaAllocator) error{OutOfMemory}!bool {
    switch (num.*) {
        NumberTag.regular_num => |_| {
            return false;
        },
        NumberTag.pair_num => |*pair| {
            if (depth == 4) {
                var node = try arena.allocator.create(ValueNode);
                node.* = ValueNode{
                    .value = 0,
                    .prev = null,
                    .next = null,
                };

                if (pair.*.left.*.regular_num.*.prev) |prev| {
                    prev.*.value += pair.*.left.regular_num.*.value;
                    node.*.prev = prev;
                    prev.*.next = node;
                }
                if (pair.*.right.*.regular_num.*.next) |next| {
                    next.*.value += pair.*.right.regular_num.*.value;
                    node.*.next = next;
                    next.*.prev = node;
                }

                num.* = Number{
                    .regular_num = node,
                };
                return true;
            } else {
                if (try explode(pair.left, depth + 1, arena)) {
                    return true;
                }
                if (try explode(pair.right, depth + 1, arena)) {
                    return true;
                }
                return false;
            }
        },
    }
}

fn split(num: *Number, arena: *std.heap.ArenaAllocator) error{OutOfMemory}!bool {
    switch (num.*) {
        NumberTag.regular_num => |node| {
            if (node.value >= 10) {
                var left = try arena.allocator.create(Number);
                var left_value = try arena.allocator.create(ValueNode);
                var right = try arena.allocator.create(Number);
                var right_value = try arena.allocator.create(ValueNode);
                left_value.* = ValueNode{
                    .value = node.value / 2,
                    .prev = node.prev,
                    .next = right_value,
                };
                left.* = Number{
                    .regular_num = left_value,
                };
                right_value.* = ValueNode{
                    .value = if (@mod(node.value, 2) == 0) node.value / 2 else node.value / 2 + 1,
                    .prev = left_value,
                    .next = node.next,
                };
                right.* = Number{
                    .regular_num = right_value,
                };

                if (node.prev) |*prev| {
                    prev.*.next = left_value;
                }
                if (node.next) |*next| {
                    next.*.prev = right_value;
                }

                num.* = Number{
                    .pair_num = Pair{
                        .left = left,
                        .right = right,
                    },
                };
                return true;
            } else {
                return false;
            }
        },
        NumberTag.pair_num => |*pair| {
            if (try split(pair.left, arena)) {
                return true;
            }
            if (try split(pair.right, arena)) {
                return true;
            }
            return false;
        },
    }
}

fn magnitude(num: Number) u32 {
    switch (num) {
        NumberTag.regular_num => |node| {
            return node.value;
        },
        NumberTag.pair_num => |pair| {
            return 3 * magnitude(pair.left.*) + 2 * magnitude(pair.right.*);
        },
    }
}

// Set up prev/next chains
fn linkTree(num: Number, allocator: *std.mem.Allocator) !void {
    var nodes = std.ArrayList(*ValueNode).init(allocator);
    defer nodes.deinit();
    try flattenNumber(num, 0, &nodes);

    var i: usize = 0;
    while (i < nodes.items.len) : (i += 1) {
        if (i != 0) {
            nodes.items[i].*.prev = nodes.items[i - 1];
        }
        if (i != nodes.items.len - 1) {
            nodes.items[i].*.next = nodes.items[i + 1];
        }
    }
}

fn clone(num: Number, arena: *std.heap.ArenaAllocator) error{OutOfMemory}!*Number {
    switch (num) {
        NumberTag.regular_num => |node| {
            var cloned_num = try arena.allocator.create(Number);
            var cloned_node = try arena.allocator.create(ValueNode);
            cloned_node.* = ValueNode{
                .value = node.value,
                .prev = null,
                .next = null,
            };
            cloned_num.* = Number{
                .regular_num = cloned_node,
            };
            return cloned_num;
        },
        NumberTag.pair_num => |pair| {
            var cloned_num = try arena.allocator.create(Number);
            cloned_num.* = Number{
                .pair_num = Pair{
                    .left = try clone(pair.left.*, arena),
                    .right = try clone(pair.right.*, arena),
                },
            };
            return cloned_num;
        },
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

    var num_total: ?*Number = null;

    var numbers = std.ArrayList(*Number).init(&gpa.allocator);
    defer numbers.deinit();

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var i: usize = 0; // Skip the first opening bracket
        var num = (try parseNumber(line, &i, &arena));

        try linkTree(num.*, &gpa.allocator);

        var cloned_number = try clone(num.*, &arena);
        try linkTree(cloned_number.*, &gpa.allocator);
        try numbers.append(cloned_number);

        // Add numbers
        if (num_total == null) {
            num_total = num;
        } else {
            num_total = try mergeNumbers(num_total.?, num, &arena);
        }

        // Reduce
        while (true) {
            if (try explode(num_total.?, 0, &arena)) {
                continue;
            }

            if (try split(num_total.?, &arena)) {
                continue;
            }

            break;
        }
    }

    var max_mag: u32 = 0;
    for (numbers.items) |num1, i| {
        for (numbers.items) |num2, j| {
            if (i == j) {
                continue;
            }
            var num1_clone = try clone(num1.*, &arena);
            try linkTree(num1_clone.*, &gpa.allocator);

            var num2_clone = try clone(num2.*, &arena);
            try linkTree(num2_clone.*, &gpa.allocator);

            var num3 = try mergeNumbers(num1_clone, num2_clone, &arena);
            while (true) {
                if (try explode(num3, 0, &arena)) {
                    continue;
                }

                if (try split(num3, &arena)) {
                    continue;
                }

                break;
            }
            max_mag = @maximum(max_mag, magnitude(num3.*));
        }
    }

    return Answer{ .@"0" = magnitude(num_total.?.*), .@"1" = max_mag };
}

pub fn main() !void {
    const answer = try run("inputs/" ++ @typeName(@This()) ++ ".txt");
    std.debug.print("{d}\n", .{answer.@"0"});
    std.debug.print("{d}\n", .{answer.@"1"});
}

test {
    const answer = try run("test-inputs/" ++ @typeName(@This()) ++ ".txt");
    try std.testing.expectEqual(answer.@"0", 4140);
    try std.testing.expectEqual(answer.@"1", 3993);
}
