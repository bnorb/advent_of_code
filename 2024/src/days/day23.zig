const std = @import("std");
const mem = std.mem;

const StringSet = std.StringHashMap(void);
const ConnMap = std.StringHashMap(StringSet);

input: []const u8,
allocator: mem.Allocator,

fn freeMap(map: *ConnMap) void {
    var it = map.valueIterator();
    while (it.next()) |set| {
        set.deinit();
    }

    map.deinit();
}

fn freeGlobalSet(this: *const @This(), set: *StringSet) void {
    var it = set.keyIterator();
    while (it.next()) |key| {
        this.allocator.free(key.*);
    }

    set.deinit();
}

fn addToMap(this: *const @This(), map: *ConnMap, key: []const u8, val: []const u8) !void {
    if (map.getPtr(key)) |set| {
        try set.put(val, undefined);
        return;
    }

    var set = StringSet.init(this.allocator);
    try set.put(val, undefined);
    try map.put(key, set);
}

fn compareStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs).compare(std.math.CompareOperator.lt);
}

fn buildGlobalKey(this: *const @This(), path: *std.ArrayList([]const u8)) ![]u8 {
    const items: [][]const u8 = try this.allocator.alloc([]const u8, path.items.len);
    defer this.allocator.free(items);
    @memcpy(items, path.items);

    mem.sort([]const u8, items, {}, compareStrings);

    var len: usize = 0;
    for (items) |item| {
        len += item.len + 1;
    }

    len -= 1;

    var key: []u8 = try this.allocator.alloc(u8, len);
    var i: usize = 0;
    for (items) |item| {
        for (item) |char| {
            key[i] = char;
            i += 1;
        }

        if (i < len) {
            key[i] = ',';
            i += 1;
        }
    }

    return key;
}

fn findSetsOfThree(this: *const @This(), curr: []const u8, map: *ConnMap, path_seen: *StringSet, global_seen: *StringSet, path: *std.ArrayList([]const u8)) !void {
    const set: *StringSet = map.getPtr(curr).?;

    if (path.items.len == 3) {
        if (!set.contains(path.items[0])) return;

        const key = try this.buildGlobalKey(path);
        if (global_seen.contains(key)) {
            this.allocator.free(key);
            return;
        }

        try global_seen.put(key, undefined);
        return;
    }

    var it = set.keyIterator();
    while (it.next()) |next| {
        if (path_seen.contains(next.*)) continue;
        try path_seen.put(next.*, undefined);
        try path.append(next.*);

        try this.findSetsOfThree(next.*, map, path_seen, global_seen, path);

        _ = path.pop();
        _ = path_seen.remove(next.*);
    }
}

fn initMap(this: *const @This(), conn_map: *ConnMap) !u32 {
    var it = mem.splitSequence(u8, this.input, "\n");
    var max: u32 = 0; // all computers have the same number of connections
    while (it.next()) |line| {
        if (line.len < 1) continue;

        const comp1 = line[0..2];
        const comp2 = line[3..];
        try this.addToMap(conn_map, comp1, comp2);
        try this.addToMap(conn_map, comp2, comp1);

        const len = conn_map.get(comp1).?.count();
        if (len > max) max = len;
    }

    return max;
}

fn collectConnections(this: *const @This(), conn_map: *ConnMap, global_seen: *StringSet) !void {
    var path_seen = StringSet.init(this.allocator);
    defer path_seen.deinit();

    var path = std.ArrayList([]const u8).init(this.allocator);
    defer path.deinit();

    var k_it = conn_map.keyIterator();
    while (k_it.next()) |key| {
        if (key.*[0] != 't') continue;

        path_seen.clearAndFree();
        path.clearAndFree();
        try path_seen.put(key.*, undefined);
        try path.append(key.*);
        try this.findSetsOfThree(key.*, conn_map, &path_seen, global_seen, &path);
    }
}

fn increaseCounter(counter: []usize, item: usize, max: usize) bool {
    if (counter[item] < max) {
        counter[item] += 1;
        return true;
    }

    if (item < counter.len - 1) {
        const can_increase = increaseCounter(counter, item + 1, max - 1);
        if (can_increase) {
            counter[item] = counter[item + 1] + 1;
        }

        return can_increase;
    }

    return false;
}

fn isFullyConnected(items: [][]const u8, conn_map: *ConnMap) bool {
    for (0..(items.len - 1)) |i| {
        const set: *StringSet = conn_map.getPtr(items[i]).?;
        for ((i + 1)..items.len) |j| {
            if (!set.contains(items[j])) return false;
        }
    }

    return true;
}

fn findFullyConnected(this: *const @This(), conn_map: *ConnMap, items: [][]const u8, used_count: u32) !?[][]const u8 {
    var counter: []usize = try this.allocator.alloc(usize, used_count);
    defer this.allocator.free(counter);

    var c: usize = 0;
    while (c < counter.len) : (c += 1) {
        counter[c] = counter.len - 1 - c;
    }

    var choice: [][]const u8 = try this.allocator.alloc([]const u8, used_count);

    const max: usize = items.len - 1;
    var can_increase = true;
    while (can_increase) {
        for (0..counter.len) |i| {
            choice[i] = items[counter[i]];
        }

        if (isFullyConnected(choice, conn_map)) {
            return choice;
        }

        can_increase = increaseCounter(counter, 0, max);
    }

    this.allocator.free(choice);
    return null;
}

pub fn part1(this: *const @This()) !?u32 {
    var global_seen = StringSet.init(this.allocator);
    defer this.freeGlobalSet(&global_seen);

    var conn_map = ConnMap.init(this.allocator);
    defer freeMap(&conn_map);

    _ = try this.initMap(&conn_map);
    try this.collectConnections(&conn_map, &global_seen);

    return global_seen.count();
}

pub fn part2(this: *const @This()) !?[]u8 {
    var global_seen = StringSet.init(this.allocator);
    defer this.freeGlobalSet(&global_seen);

    var conn_map = ConnMap.init(this.allocator);
    defer freeMap(&conn_map);

    var conn_count = try this.initMap(&conn_map);
    var items: [][]const u8 = try this.allocator.alloc([]const u8, conn_count);
    defer this.allocator.free(items);

    while (conn_count > 0) : (conn_count -= 1) {
        var it = conn_map.iterator();

        while (it.next()) |entry| {
            var connections = entry.value_ptr.keyIterator();
            var i: usize = 0;
            while (connections.next()) |conn| : (i += 1) {
                items[i] = conn.*;
            }

            if (try this.findFullyConnected(&conn_map, items, conn_count)) |list| {
                defer this.allocator.free(list);
                var path = std.ArrayList([]const u8).init(this.allocator);
                defer path.deinit();

                try path.append(entry.key_ptr.*);
                for (list) |item| {
                    try path.append(item);
                }

                return try this.buildGlobalKey(&path);
            }
        }
    }

    return null;
}

test "sample input" {
    const allocator = std.testing.allocator;
    const input = "kh-tc\nqp-kh\nde-cg\nka-co\nyn-aq\nqp-ub\ncg-tb\nvc-aq\ntb-ka\nwh-tc\nyn-cg\nkh-ub\nta-co\nde-co\ntc-td\ntb-wq\nwh-td\nta-ka\ntd-qp\naq-cg\nwq-ub\nub-vc\nde-ta\nwq-aq\nwq-vc\nwh-yn\nka-de\nkh-ta\nco-tc\nwh-qp\ntb-vc\ntd-yn\n";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(7, try problem.part1());

    const res = (try problem.part2()).?;
    defer allocator.free(res);

    try std.testing.expectEqualStrings("co,de,ka,ta", res);
}
