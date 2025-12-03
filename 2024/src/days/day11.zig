const std = @import("std");
const mem = std.mem;

const Cache = std.AutoHashMap([2]u64, u64);

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?u64 {
    var cache = Cache.init(this.allocator);
    defer cache.deinit();

    var sum: u64 = 0;
    var it = mem.splitScalar(u8, this.input[0 .. this.input.len - 1], ' '); // len-1 because of linebreak
    while (it.next()) |num| {
        const stone = std.fmt.parseInt(u64, num, 10) catch continue;
        const stone_count = try calcStone(&cache, stone, 25);
        sum += stone_count;
    }

    return sum;
}

pub fn part2(this: *const @This()) !?u64 {
    var cache = Cache.init(this.allocator);
    defer cache.deinit();

    var sum: u64 = 0;
    var it = mem.splitScalar(u8, this.input[0 .. this.input.len - 1], ' '); // len-1 because of linebreak
    while (it.next()) |num| {
        const stone = std.fmt.parseInt(u64, num, 10) catch continue;
        const stone_count = try calcStone(&cache, stone, 75);
        sum += stone_count;
    }

    return sum;
}

fn calcStone(cache: *Cache, stone: u64, blinks_left: u8) !u64 {
    if (blinks_left == 0) {
        return 1;
    }

    if (cache.get(.{ stone, blinks_left })) |cached| {
        return cached;
    }

    var sum: u64 = 0;
    if (stone == 0) {
        sum += try calcStone(cache, 1, blinks_left - 1);
    } else if (getSides(stone)) |sides| {
        sum += try calcStone(cache, sides[0], blinks_left - 1);
        sum += try calcStone(cache, sides[1], blinks_left - 1);
    } else {
        sum += try calcStone(cache, stone * 2024, blinks_left - 1);
    }

    try cache.put(.{ stone, blinks_left }, sum);

    return sum;
}

fn getSides(stone: u64) ?[2]u64 {
    const digits = countDigits(stone);
    if (digits % 2 != 0) {
        return null;
    }

    const left = stone / std.math.pow(u64, 10, digits / 2);
    const right = stone - (left * std.math.pow(u64, 10, digits / 2));

    return .{ left, right };
}

fn countDigits(stone: u64) u64 {
    if (stone == 0) return 1;

    var digits: u64 = 0;
    var val = stone;
    while (val > 0) {
        digits += 1;
        val = val / 10;
    }

    return digits;
}

test "sample input" {
    const allocator = std.testing.allocator;
    const input = "125 17\n";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(55312, try problem.part1());
    try std.testing.expectEqual(65601038650482, try problem.part2());
}

test countDigits {
    try std.testing.expectEqual(1, countDigits(0));
    try std.testing.expectEqual(1, countDigits(1));
    try std.testing.expectEqual(1, countDigits(9));
    try std.testing.expectEqual(2, countDigits(10));
    try std.testing.expectEqual(2, countDigits(11));
    try std.testing.expectEqual(2, countDigits(99));
    try std.testing.expectEqual(3, countDigits(100));
    try std.testing.expectEqual(4, countDigits(1000));
}

test getSides {
    try std.testing.expectEqual(.{ 56, 87 }, getSides(5687));
    try std.testing.expectEqual(.{ 1234, 1234 }, getSides(12341234));
    try std.testing.expectEqual(.{ 2147895, 2365478 }, getSides(21478952365478));
    try std.testing.expectEqual(null, getSides(1));
    try std.testing.expectEqual(null, getSides(134));
    try std.testing.expectEqual(null, getSides(1231234));
}
