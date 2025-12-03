const std = @import("std");
const mem = std.mem;

const Set = std.AutoHashMap(u8, void);
const Map = std.AutoHashMap(u8, Set);
const List = std.ArrayList(std.ArrayList(u8));

const Printer = struct {
    isBefore: Map,
    isAfter: Map,
    rows: List,

    pub fn init(allocator: mem.Allocator) Printer {
        return Printer{
            .isBefore = Map.init(allocator),
            .isAfter = Map.init(allocator),
            .rows = List.init(allocator),
        };
    }

    pub fn free(this: *@This()) void {
        freeMap(&this.isBefore);
        freeMap(&this.isAfter);

        for (this.rows.items) |row| {
            row.deinit();
        }

        this.rows.deinit();
    }

    pub fn parse(this: *@This(), allocator: mem.Allocator, input: []const u8) !void {
        var parts = mem.splitSequence(u8, input, "\n\n");
        const mapping = parts.first();
        const rows = parts.next().?;

        var it = mem.splitSequence(u8, mapping, "\n");
        while (it.next()) |line| {
            var line_it = mem.splitScalar(u8, line, '|');
            const x = try std.fmt.parseInt(u8, line_it.first(), 10);
            const y = try std.fmt.parseInt(u8, line_it.next().?, 10);

            try addToMap(allocator, x, y, &this.isBefore);
            try addToMap(allocator, y, x, &this.isAfter);
        }

        var row_it = mem.splitSequence(u8, rows, "\n");
        while (row_it.next()) |line| {
            if (line.len < 1) continue;

            var r = std.ArrayList(u8).init(allocator);
            var line_it = mem.splitScalar(u8, line, ',');
            while (line_it.next()) |num| {
                const n = try std.fmt.parseInt(u8, num, 10);
                try r.append(n);
            }

            try this.rows.append(r);
        }
    }

    pub fn findCorrectMiddles(this: *const @This(), allocator: mem.Allocator) !std.ArrayList(u8) {
        var result = std.ArrayList(u8).init(allocator);
        for (this.rows.items) |row| {
            if (this.isCorrectRow(row.items)) {
                const index = @divTrunc(row.items.len, 2);
                try result.append(row.items[index]);
            }
        }

        return result;
    }

    pub fn findFixedMiddles(this: *const @This(), allocator: mem.Allocator) !std.ArrayList(u8) {
        var result = std.ArrayList(u8).init(allocator);
        for (this.rows.items) |row| {
            if (!this.isCorrectRow(row.items)) {
                const index = @divTrunc(row.items.len, 2);
                std.mem.sort(u8, row.items, this, lessThan);
                try result.append(row.items[index]);
            }
        }

        return result;
    }

    pub fn print(this: *const @This()) void {
        printMap(&this.isBefore);
        std.debug.print("\n", .{});
        printMap(&this.isAfter);

        std.debug.print("\n", .{});
        std.debug.print("Rows:\n", .{});
        for (this.rows.items) |item| {
            std.debug.print("{any}\n ", .{item.items});
        }
    }

    fn lessThan(ctx: *const @This(), lhs: u8, rhs: u8) bool {
        if (ctx.isBefore.get(lhs)) |set| {
            if (set.contains(rhs)) {
                return true;
            }
        }

        if (ctx.isBefore.get(rhs)) |set| {
            if (set.contains(lhs)) {
                return false;
            }
        }

        if (ctx.isAfter.get(lhs)) |set| {
            if (set.contains(rhs)) {
                return false;
            }
        }

        if (ctx.isAfter.get(rhs)) |set| {
            if (set.contains(lhs)) {
                return true;
            }
        }

        return true;
    }

    fn isCorrectRow(this: *const @This(), row: []u8) bool {
        for (row, 0..) |item, index| {
            var j: usize = 0;
            while (j < row.len) : (j += 1) {
                if (j < index) {
                    if (this.isBefore.get(item)) |set| {
                        if (set.contains(row[j])) {
                            return false;
                        }
                    }

                    if (this.isAfter.get(row[j])) |set| {
                        if (set.contains(item)) {
                            return false;
                        }
                    }
                } else if (j > index) {
                    if (this.isBefore.get(row[j])) |set| {
                        if (set.contains(item)) {
                            return false;
                        }
                    }

                    if (this.isAfter.get(row[j])) |set| {
                        if (set.contains(row[j])) {
                            return false;
                        }
                    }
                }
            }
        }

        return true;
    }

    fn printMap(map: *const Map) void {
        var it = map.keyIterator();
        while (it.next()) |key| {
            std.debug.print("{d} < ", .{key.*});
            var val: Set = map.get(key.*).?;
            var set_it = val.keyIterator();
            while (set_it.next()) |k| {
                std.debug.print("{d} ", .{k.*});
            }

            std.debug.print("\n", .{});
        }
    }

    fn freeMap(map: *Map) void {
        var it = map.keyIterator();
        while (it.next()) |key| {
            var val: Set = map.get(key.*).?;
            val.deinit();
        }

        map.deinit();
    }

    fn addToMap(allocator: mem.Allocator, key: u8, value: u8, map: *Map) !void {
        if (!map.contains(key)) {
            var set = Set.init(allocator);
            try set.put(value, undefined);
            try map.put(key, set);
        } else {
            var set: *Set = map.getPtr(key).?;
            try set.put(value, undefined);
        }
    }
};

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?u32 {
    var printer = Printer.init(this.allocator);
    defer printer.free();

    try printer.parse(this.allocator, this.input);
    const results = try printer.findCorrectMiddles(this.allocator);
    defer results.deinit();
    var sum: u32 = 0;
    for (results.items) |num| {
        sum += @intCast(num);
    }

    return sum;
}

pub fn part2(this: *const @This()) !?i64 {
    var printer = Printer.init(this.allocator);
    defer printer.free();

    try printer.parse(this.allocator, this.input);
    const results = try printer.findFixedMiddles(this.allocator);
    defer results.deinit();

    var sum: u32 = 0;
    for (results.items) |num| {
        sum += @intCast(num);
    }

    return sum;
}

test "sample input" {
    const allocator = std.testing.allocator;
    const input = "47|53\n97|13\n97|61\n97|47\n75|29\n61|13\n75|53\n29|13\n97|29\n53|29\n61|53\n97|53\n61|29\n47|13\n75|47\n97|75\n47|61\n75|61\n47|29\n75|13\n53|13\n\n75,47,61,53,29\n97,61,53,29,13\n75,29,13\n75,97,47,61,53\n61,13,29\n97,13,75,29,47\n";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(143, try problem.part1());
    try std.testing.expectEqual(123, try problem.part2());
}
