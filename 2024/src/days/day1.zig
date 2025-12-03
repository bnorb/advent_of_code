const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?u32 {
    const lists = try this.getLists();
    var left = lists[0];
    defer left.deinit();
    var right = lists[1];
    defer right.deinit();

    const left_items = try left.toOwnedSlice();
    defer this.allocator.free(left_items);
    mem.sort(u32, left_items, {}, comptime std.sort.asc(u32));

    const right_items = try right.toOwnedSlice();
    defer this.allocator.free(right_items);
    mem.sort(u32, right_items, {}, comptime std.sort.asc(u32));

    var sum: u32 = 0;

    for (left_items, 0..) |left_value, index| {
        const right_value = right_items[index];

        if (right_value > left_value) {
            sum += right_value - left_value;
        } else {
            sum += left_value - right_value;
        }
    }

    return sum;
}

pub fn part2(this: *const @This()) !?i64 {
    const lists = try this.getLists();
    var left = lists[0];
    defer left.deinit();
    var right = lists[1];
    defer right.deinit();

    var right_map = std.AutoHashMap(u32, u32).init(this.allocator);
    defer right_map.deinit();

    for (right.items) |item| {
        if (right_map.get(item)) |count| {
            try right_map.put(item, count + 1);
        } else {
            try right_map.put(item, 1);
        }
    }

    var sum: u32 = 0;
    for (left.items) |item| {
        var mult: u32 = 0;
        if (right_map.get(item)) |count| {
            mult = count;
        }

        sum += item * mult;
    }

    return sum;
}

fn getLists(this: *const @This()) ![2]std.ArrayList(u32) {
    var left = std.ArrayList(u32).init(this.allocator);
    var right = std.ArrayList(u32).init(this.allocator);

    var it = mem.splitSequence(u8, this.input, "\n");
    while (it.next()) |line| {
        if (line.len < 1) {
            continue;
        }

        var line_it = mem.splitSequence(u8, line, "   ");
        const left_value = try std.fmt.parseInt(u32, line_it.first(), 10);
        const right_value = try std.fmt.parseInt(u32, line_it.next().?, 10);

        try left.append(left_value);
        try right.append(right_value);
    }

    return .{ left, right };
}

test "sample input" {
    const allocator = std.testing.allocator;
    const input = "3   4\n4   3\n2   5\n1   3\n3   9\n3   3\n";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(11, try problem.part1());
    try std.testing.expectEqual(31, try problem.part2());
}
