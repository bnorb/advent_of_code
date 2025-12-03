const std = @import("std");
const mem = std.mem;

const List = std.ArrayList([]const u8);
const TowelSet = std.StringHashMap(void);
const ArrangementCache = std.StringHashMap(u64);

input: []const u8,
allocator: mem.Allocator,

fn parse_towels(line: []const u8, towels: *TowelSet, dedupe: bool) !usize {
    var it = mem.splitSequence(u8, line, ", ");

    var max: usize = 0;
    while (it.next()) |towel| {
        try towels.put(towel, undefined);
        if (towel.len > max) max = towel.len;
    }

    var final_max: usize = 0;
    if (dedupe) {
        var key_it = towels.keyIterator();
        while (key_it.next()) |key| {
            var copy = try towels.clone();
            errdefer copy.deinit();

            _ = copy.remove(key.*);
            if (isConfigViable(key.*, 0, &copy, max)) {
                _ = towels.removeByPtr(key);
            } else if (key.*.len > final_max) {
                final_max = key.*.len;
            }

            copy.deinit();
        }
    } else {
        final_max = max;
    }

    return final_max;
}

fn isConfigViable(config: []const u8, current_letter: usize, towels: *TowelSet, max_towel_len: usize) bool {
    if (current_letter >= config.len) {
        return true;
    }

    var len: usize = max_towel_len;
    while (len > 0) : (len -= 1) {
        if (current_letter + len > config.len) continue;
        const part = config[current_letter .. current_letter + len];
        if (towels.contains(part)) {
            if (isConfigViable(config, current_letter + len, towels, max_towel_len)) {
                return true;
            }
        }
    }

    return false;
}

fn countConfigArrangements(config: []const u8, current_letter: usize, towels: *TowelSet, cache: *ArrangementCache, max_towel_len: usize) !u64 {
    if (current_letter >= config.len) return 1;

    var len: usize = max_towel_len;
    var count: u64 = 0;

    while (len > 0) : (len -= 1) {
        if (current_letter + len > config.len) continue;

        const part = config[current_letter .. current_letter + len];
        if (!towels.contains(part)) continue;

        if (cache.get(config[current_letter + len ..])) |c| {
            count += c;
            continue;
        }

        const sub_count = try countConfigArrangements(config, current_letter + len, towels, cache, max_towel_len);
        try cache.put(config[current_letter + len ..], sub_count);
        count += sub_count;
    }

    return count;
}

pub fn part1(this: *const @This()) !?u32 {
    var towels = TowelSet.init(this.allocator);
    defer towels.deinit();

    var it = mem.splitSequence(u8, this.input, "\n");
    const max_towel_len = try parse_towels(it.next().?, &towels, true);

    _ = it.next();
    var count: u32 = 0;
    while (it.next()) |config| {
        if (config.len < 1) continue;

        if (isConfigViable(config, 0, &towels, max_towel_len)) {
            count += 1;
        }
    }

    return count;
}

pub fn part2(this: *const @This()) !?u64 {
    var towels = TowelSet.init(this.allocator);
    defer towels.deinit();

    var it = mem.splitSequence(u8, this.input, "\n");
    const max_towel_len = try parse_towels(it.next().?, &towels, false);

    var cache = ArrangementCache.init(this.allocator);
    defer cache.deinit();

    var sum: u64 = 0;
    _ = it.next();
    while (it.next()) |config| {
        if (config.len < 1) continue;

        const counter = try countConfigArrangements(config, 0, &towels, &cache, max_towel_len);
        sum += counter;
    }

    return sum;
}

test "sample input" {
    const allocator = std.testing.allocator;
    const input = "r, wr, b, g, bwu, rb, gb, br\n\nbrwrr\nbggr\ngbbr\nrrbgbr\nubwu\nbwurrg\nbrgr\nbbrgwb\n";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(6, try problem.part1());
    try std.testing.expectEqual(16, try problem.part2());
}
