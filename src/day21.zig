const std = @import("std");
const Answer = struct { @"0": u32, @"1": u64 };

const WinLoss = struct {
    wins: u64,
    losses: u64,
};

fn add_win_loss(u: WinLoss, v: WinLoss) WinLoss {
    return WinLoss{
        .wins = u.wins + v.wins,
        .losses = u.losses + v.losses,
    };
}

fn scale_win_loss(c: u64, v: WinLoss) WinLoss {
    return WinLoss{
        .wins = c * v.wins,
        .losses = c * v.losses,
    };
}

fn play_deterministic(init_positions: [2]u32) u32 {
    var die: u32 = 0;
    var scores = [2]u32{ 0, 0 };
    var positions = init_positions;
    var player_i: usize = 0;

    var num_rolls: u32 = 0;
    while (true) {
        var roll_i: usize = 0;
        while (roll_i < 3) : (roll_i += 1) {
            positions[player_i] = @mod(positions[player_i] + die + 1, 10);
            die = @mod(die + 1, 100);
        }
        num_rolls += 3;
        scores[player_i] += positions[player_i] + 1;

        if (scores[player_i] >= 1000) {
            return scores[1 - player_i] * num_rolls;
        }

        player_i = 1 - player_i;
    }
}

fn play_dirac(init_positions: [2]u32, init_scores: [2]u32, player_i: usize) WinLoss {
    if (init_scores[1 - player_i] >= 21) {
        if (player_i == 0) {
            return WinLoss{
                .wins = 0,
                .losses = 1,
            };
        } else {
            return WinLoss{
                .wins = 1,
                .losses = 0,
            };
        }
    }

    var win_loss = WinLoss{
        .wins = 0,
        .losses = 0,
    };

    const ways = [_]u64{ 1, 3, 6, 7, 6, 3, 1 };
    inline for (ways) |num_ways, i| {
        var positions = init_positions;
        positions[player_i] = @mod(positions[player_i] + (3 + @intCast(u32, i)), 10);
        var scores = init_scores;
        scores[player_i] += positions[player_i] + 1;
        win_loss = add_win_loss(
            win_loss,
            scale_win_loss(num_ways, play_dirac(positions, scores, 1 - player_i)),
        );
    }

    return win_loss;
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

    var positions: [2]u32 = undefined;
    var player_i: usize = 0;
    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| : (player_i += 1) {
        var tokens = std.mem.tokenize(u8, line, " :");
        var i: usize = 0;
        while (tokens.next()) |token| : (i += 1) {
            if (i == 4) {
                positions[player_i] = (try std.fmt.parseInt(u32, token, 10)) - 1;
                break;
            }
        }
    }

    const dirac_win_loss = play_dirac(positions, [2]u32{ 0, 0 }, 0);

    return Answer{
        .@"0" = play_deterministic(positions),
        .@"1" = @maximum(dirac_win_loss.wins, dirac_win_loss.losses),
    };
}

pub fn main() !void {
    const answer = try run("inputs/" ++ @typeName(@This()) ++ ".txt");
    std.debug.print("{d}\n", .{answer.@"0"});
    std.debug.print("{d}\n", .{answer.@"1"});
}

test {
    const answer = try run("test-inputs/" ++ @typeName(@This()) ++ ".txt");
    try std.testing.expectEqual(answer.@"0", 739785);
    try std.testing.expectEqual(answer.@"1", 444356092776315);
}
