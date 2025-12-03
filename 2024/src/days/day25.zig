const std = @import("std");
const mem = std.mem;

const LockList = std.ArrayList([5]u8);

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?i64 {
    var locks = LockList.init(this.allocator);
    defer locks.deinit();

    var it = mem.splitSequence(u8, this.input, "\n\n");
    while (it.next()) |block| {
        var in_it = mem.splitSequence(u8, block, "\n");
        if (mem.eql(u8, in_it.next().?, "#####")) {
            var pins: [5]u8 = .{ 0, 0, 0, 0, 0 };
            while (in_it.next()) |line| {
                if (line.len != 5) continue;

                for (line, 0..5) |char, i| {
                    if (char == '#') pins[i] += 1;
                }
            }

            try locks.append(pins);
        }
    }

    var count: u32 = 0;

    it.reset();
    while (it.next()) |block| {
        var in_it = mem.splitSequence(u8, block, "\n");
        if (mem.eql(u8, in_it.next().?, ".....")) {
            var key_heights: [5]u8 = .{ 5, 5, 5, 5, 5 };
            while (in_it.next()) |line| {
                if (line.len != 5) continue;

                for (line, 0..5) |char, i| {
                    if (char == '.') key_heights[i] -= 1;
                }
            }

            for (locks.items) |lock| {
                var matches: u8 = 0;
                for (lock, key_heights) |l, k| {
                    if (l + k <= 5) matches += 1;
                }

                if (matches == 5) {
                    count += 1;
                }
            }
        }
    }

    return count;
}

pub fn part2(this: *const @This()) !?i64 {
    _ = this;
    return null;
}

test "sample input" {
    const allocator = std.testing.allocator;
    const input = "#####\n.####\n.####\n.####\n.#.#.\n.#...\n.....\n\n#####\n##.##\n.#.##\n...##\n...#.\n...#.\n.....\n\n.....\n#....\n#....\n#...#\n#.#.#\n#.###\n#####\n\n.....\n.....\n#.#..\n###..\n###.#\n###.#\n#####\n\n.....\n.....\n.....\n#....\n#.#..\n#.#.#\n#####\n";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(3, try problem.part1());
    try std.testing.expectEqual(null, try problem.part2());
}
