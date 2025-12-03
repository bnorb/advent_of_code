const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

fn mix(secret: u64, next: u64) u64 {
    return next ^ secret;
}

fn prune(secret: u64) u64 {
    return secret % 16777216;
}

fn mul(secret: u64, op: u64) u64 {
    var next: u64 = secret * op;
    next = mix(secret, next);

    return prune(next);
}

fn div(secret: u64, op: u64) u64 {
    var next: u64 = @divTrunc(secret, op);
    next = mix(secret, next);

    return prune(next);
}

fn nextSecret(secret: u64) u64 {
    var next: u64 = mul(secret, 64);
    next = div(next, 32);
    return mul(next, 2048);
}

fn getPrice(secret: u64) i8 {
    return @intCast(secret % 10);
}

fn moveWindow(window: *[4]i8, new_value: i8) void {
    window[0] = window[1];
    window[1] = window[2];
    window[2] = window[3];
    window[3] = new_value;
}

pub fn part1(this: *const @This()) !?u64 {
    var it = mem.splitSequence(u8, this.input, "\n");

    var sum: u64 = 0;
    while (it.next()) |start_num| {
        if (start_num.len < 1) continue;

        var num = try std.fmt.parseInt(u64, start_num, 10);
        var i: usize = 0;
        while (i < 2000) : (i += 1) {
            num = nextSecret(num);
        }

        sum += num;
    }

    return sum;
}

pub fn part2(this: *const @This()) !?u64 {
    var sum_map = std.AutoHashMap([4]i8, u64).init(this.allocator);
    defer sum_map.deinit();
    var seen = std.AutoHashMap([4]i8, void).init(this.allocator);
    defer seen.deinit();

    var it = mem.splitSequence(u8, this.input, "\n");
    while (it.next()) |start_num| {
        if (start_num.len < 1) continue;

        seen.clearAndFree();

        var num = try std.fmt.parseInt(u64, start_num, 10);
        var i: usize = 0;
        var window: [4]i8 = .{ 0, 0, 0, 0 };
        var prev_price: i8 = getPrice(num);
        while (i < 2000) : (i += 1) {
            num = nextSecret(num);
            const price = getPrice(num);
            const diff = price - prev_price;
            moveWindow(&window, diff);

            if (i > 2 and !seen.contains(window)) {
                try seen.put(window, undefined);
                var curr_sum: u64 = 0;
                if (sum_map.get(window)) |sum| {
                    curr_sum = sum;
                }

                try sum_map.put(window, curr_sum + @as(u64, @intCast(price)));
            }

            prev_price = price;
        }
    }

    var max: u64 = 0;
    var val_it = sum_map.valueIterator();
    while (val_it.next()) |bananas| {
        if (bananas.* > max) max = bananas.*;
    }

    return max;
}

test "sample input" {
    const allocator = std.testing.allocator;

    var problem: @This() = .{
        .input = "1\n10\n100\n2024\n",
        .allocator = allocator,
    };

    try std.testing.expectEqual(37327623, try problem.part1());
    problem.input = "1\n2\n3\n2024\n";
    try std.testing.expectEqual(23, try problem.part2());
}
