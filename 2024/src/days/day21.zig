const std = @import("std");
const mem = std.mem;

const DIRS: [4][2]isize = .{
    .{ -1, 0 },
    .{ 1, 0 },
    .{ 0, -1 },
    .{ 0, 1 },
};

const DIR_CHARS: [4]u8 = .{
    '^',
    'v',
    '<',
    '>',
};

const ChoiceMap = std.AutoHashMap([2]u8, struct { []const u8, ?[]const u8 });
const SegmentList = std.ArrayList(struct { []const u8, ?[]const u8 });
const CountCache = std.StringHashMap(std.AutoHashMap(u8, usize));

// Repeating segments:
// > -> < : [<<A] # won't happen
// < -> > : [>>A] # won't happen
// ^ -> v : [vA]  # won't happen
// v -> ^ : [^A]  # won't happen

// A -> > : [vA] -> [v<A / <vA] [>^A / ^>A]
// A -> ^ : [<A] -> [<v<A / v<<A] [>^>A / >>^A]
// v -> < : [<A]
// > -> v : [<A]
// > -> A : [^A] -> [<A] [>A]
// ^ -> A : [>A] -> [vA] [^A]
// v -> > : [>A]
// < -> v : [>A]

// < -> ^ : [>^A] -> [vA] [<^A /^<A] [>A]
// ^ -> < : [v<A] -> [v<A / <vA] [<A] [>>^A / >^>A]

// A -> v : [<vA]  [v<A] -> [[v<<A / <v<A] [>A] [>^A / ^>A]]  [[v<A / <vA] [<A] [>>^A / >^>A]]
// v -> A : [>^A]  [^>A] -> [[vA] [<^A /^<A] [>A]]            [[<A] [v>A / >vA] [^A]]
// > -> ^ : [^<A]  [<^A] -> [[<A] [v<A] [>>^A / >^>A]]        [[<v<A / v<<A] [>^A] [>A]]
// ^ -> > : [v>A]  [>vA] -> [[<vA / v<A] [>A] [^A]]           [[vA] [<A] [>^A / ^>A]]

// A -> < : [<v<A] [v<<A] -> [[<v<A / v<<A] [>A] [<A] [>>^A / >^>A]]  [[<vA / v<A] [<A] [A] [>>^A / >^>A]] ([12] [10])
// < -> A : [>^>A] [>>^A] -> [[vA] [<^A / ^<A] [>vA / v>A] [^A]]      [[vA] [A] [<^A / ^<A] [>A]]          ([10] [8])

// [vA]:
//   [v<A] [>^A]
//   [v<A] [^>A]
//   [<vA] [>^A]
//   [<vA] [^>A]

// [<A]:
//   [v<<A] [>>^A]

// [^A]:
//   [<A] [>A]

// [>A]:
//   [vA] [^A]

// [v<A]:
//   [v<A] [<A] [>>^A]
//   [<vA] [<A] [>>^A]

// [<vA]:
//   [v<<A] [>A] [>^A]
//   [v<<A] [>A] [^>A]
//   [<v<A] [>A] [>^A]
//   [<v<A] [>A] [^>A]

// [>^A]:
//   [vA] [<^A] [>A]
//   [vA] [^<A] [>A]

// [^>A]:
//   [<A] [v>A] [^A]
//   [<A] [>vA] [^A]

// [^<A]:
//   [<A] [v<A] [>>^A]

// [<^A]:
//   [v<<A] [>^A] [>A]

// [>vA]:
//   [vA] [<A] [>^A]
//   [vA] [<A] [^>A]

// [v>A]:
//   [vA] [<A] [>^A]
//   [vA] [<A] [^>A]

// [v<<A]:
//   [<vA] [<A] [A] [>>^A]
//   [v<A] [<A] [A] [>>^A]

// [>>^A]:
//   [vA] [A] [<^A] [>A]
//   [vA] [A] [^<A] [>A]
const DirPad = struct {
    arena: *std.heap.ArenaAllocator,
    choice_map: ChoiceMap,
    count_cache: CountCache,

    pub fn init(arena: *std.heap.ArenaAllocator) !DirPad {
        const allocator = arena.allocator();
        var map = ChoiceMap.init(allocator);
        try map.put(.{ 'A', '>' }, .{ "vA", null });
        try map.put(.{ 'A', '^' }, .{ "<A", null });
        try map.put(.{ 'v', '<' }, .{ "<A", null });
        try map.put(.{ '>', 'v' }, .{ "<A", null });
        try map.put(.{ '>', 'A' }, .{ "^A", null });
        try map.put(.{ '^', 'A' }, .{ ">A", null });
        try map.put(.{ 'v', '>' }, .{ ">A", null });
        try map.put(.{ '<', 'v' }, .{ ">A", null });
        try map.put(.{ '<', '^' }, .{ ">^A", null });
        try map.put(.{ '^', '<' }, .{ "v<A", null });
        try map.put(.{ 'A', 'v' }, .{ "v<A", "<vA" });
        try map.put(.{ 'v', 'A' }, .{ ">^A", "^>A" });
        try map.put(.{ '>', '^' }, .{ "^<A", "<^A" });
        try map.put(.{ '^', '>' }, .{ ">vA", "v>A" });
        try map.put(.{ 'A', '<' }, .{ "v<<A", null }); // other choice is always worse
        try map.put(.{ '<', 'A' }, .{ ">>^A", null }); // other choice is always worse

        return DirPad{
            .arena = arena,
            .choice_map = map,
            .count_cache = CountCache.init(allocator),
        };
    }

    pub fn countInstructions(this: *@This(), first_input: []const u8, levels: u8) !usize {
        const segments = try this.getSegments(first_input);

        var count: usize = 0;
        for (segments.items) |choices| {
            var child_count = try this.calcSegment(choices[0], levels - 1);
            if (choices[1]) |other| {
                const other_count = try this.calcSegment(other, levels - 1);
                if (other_count < child_count) child_count = other_count;
            }

            count += child_count;
        }

        return count;
    }

    fn getSegments(this: *@This(), input: []const u8) !SegmentList {
        var segments = SegmentList.init(this.arena.allocator());
        var curr_char: u8 = 'A';
        for (input) |char| {
            var segment: struct { []const u8, ?[]const u8 } = undefined;
            if (curr_char == char) {
                segment = .{ "A", null };
            } else {
                segment = this.choice_map.get(.{ curr_char, char }).?;
            }

            try segments.append(segment);
            curr_char = char;
        }

        return segments;
    }

    fn getCount(segments: SegmentList) usize {
        var count: usize = 0;
        for (segments.items) |segment| {
            count += segment[0].len; // len is same regardless of choice
        }

        return count;
    }

    fn putToCache(this: *@This(), segment: []const u8, level: u8, count: usize) !void {
        if (this.count_cache.getPtr(segment)) |level_cache| {
            try level_cache.put(level, count);
        } else {
            var level_cache = std.AutoHashMap(u8, usize).init(this.arena.allocator());
            try level_cache.put(level, count);
            try this.count_cache.put(segment, level_cache);
        }
    }

    fn calcSegment(this: *@This(), segment: []const u8, levels: u8) !usize {
        if (this.count_cache.get(segment)) |level_cache| {
            if (level_cache.get(levels)) |count| {
                return count;
            }
        }

        const segments = try this.getSegments(segment);
        defer segments.deinit();

        if (levels == 1) {
            const count = getCount(segments);
            try this.putToCache(segment, levels, count);
            return count;
        }

        var count: usize = 0;
        for (segments.items) |choices| {
            var child_count = try this.calcSegment(choices[0], levels - 1);
            if (choices[1]) |other| {
                const other_count = try this.calcSegment(other, levels - 1);
                if (other_count < child_count) child_count = other_count;
            }

            count += child_count;
        }

        try this.putToCache(segment, levels, count);
        return count;
    }
};

const NumPad = struct {
    arena: *std.heap.ArenaAllocator,
    matrix: [4][3]u8 = .{
        .{ '7', '8', '9' },
        .{ '4', '5', '6' },
        .{ '1', '2', '3' },
        .{ '#', '0', 'A' },
    },

    pub fn init(arena: *std.heap.ArenaAllocator) !NumPad {
        return NumPad{
            .arena = arena,
        };
    }

    pub fn sequenceToPath(this: *@This(), sequence: []const u8) !std.ArrayList([]u8) {
        const allocator = this.arena.allocator();
        var current_path = std.ArrayList(u8).init(allocator);
        var segment_paths: [][][]u8 = try allocator.alloc([][]u8, sequence.len);

        var curr_char: u8 = 'A';
        for (sequence, 0..sequence.len) |char, segment_idx| {
            var paths: std.ArrayList([]u8) = undefined;

            paths = std.ArrayList([]u8).init(allocator);
            current_path.clearAndFree();
            const from_coords = this.getCoords(curr_char);
            const to_coords = this.getCoords(char);

            try this.findPaths(from_coords, to_coords, getDirs(from_coords, to_coords), &current_path, &paths);

            segment_paths[segment_idx] = try allocator.alloc([]u8, paths.items.len);
            for (paths.items, 0..paths.items.len) |path, path_idx| {
                segment_paths[segment_idx][path_idx] = try allocator.alloc(u8, path.len);
                @memcpy(segment_paths[segment_idx][path_idx], path);
            }

            curr_char = char;
        }

        return try this.buildCartesian(segment_paths);
    }

    fn buildCartesian(this: *const @This(), segment_paths: [][][]u8) !std.ArrayList([]u8) {
        const allocator = this.arena.allocator();
        var paths = std.ArrayList([]u8).init(allocator);
        var counter: []usize = try allocator.alloc(usize, segment_paths.len);
        for (0..counter.len) |i| {
            counter[i] = 0;
        }

        outer: while (true) {
            var path_len: usize = 0;
            for (segment_paths, counter) |sp, c| {
                path_len += sp[c].len;
            }

            var path = try allocator.alloc(u8, path_len);
            var i: usize = 0;
            for (segment_paths, counter) |sp, c| {
                for (sp[c]) |char| {
                    path[i] = char;
                    i += 1;
                }
            }

            try paths.append(path);

            i = 0;
            while (i < counter.len) : (i += 1) {
                if (counter[i] < segment_paths[i].len - 1) {
                    counter[i] += 1;
                    break;
                }

                counter[i] = 0;
                if (i == counter.len - 1) {
                    break :outer;
                }
            }
        }

        return paths;
    }

    fn findPaths(this: *const @This(), curr: [2]usize, end: [2]usize, dirs: [4]?[2]isize, current_path: *std.ArrayList(u8), paths: *std.ArrayList([]u8)) !void {
        if (curr[0] == end[0] and curr[1] == end[1]) {
            try current_path.append('A');
            const path: []u8 = try this.arena.allocator().alloc(u8, current_path.items.len);
            @memcpy(path, current_path.items);
            try paths.append(path);
            _ = current_path.pop();

            return;
        }

        const neighbors = getNeighbors(curr, dirs);
        for (neighbors, 0..4) |neighbor, i| {
            if (neighbor == null) continue;
            if (getInBounds(neighbor.?)) |next| {
                if (this.matrix[next[0]][next[1]] == '#') continue;

                try current_path.append(DIR_CHARS[i]);
                try this.findPaths(next, end, dirs, current_path, paths);
                _ = current_path.pop();
            }
        }
    }

    fn getDirs(from: [2]usize, to: [2]usize) [4]?[2]isize {
        var dirs: [4]?[2]isize = .{ DIRS[0], DIRS[1], DIRS[2], DIRS[3] };
        if (from[0] >= to[0]) dirs[1] = null;
        if (from[0] <= to[0]) dirs[0] = null;

        if (from[1] >= to[1]) dirs[3] = null;
        if (from[1] <= to[1]) dirs[2] = null;

        return dirs;
    }

    fn getCoords(this: *const @This(), char: u8) [2]usize {
        for (this.matrix, 0..4) |row, r| {
            for (row, 0..3) |cell, c| {
                if (char == cell) return .{ @intCast(r), @intCast(c) };
            }
        }

        unreachable;
    }

    fn getNeighbors(curr: [2]usize, dirs: [4]?[2]isize) [4]?[2]isize {
        var neighbors: [4]?[2]isize = dirs;
        const c: [2]isize = .{ @intCast(curr[0]), @intCast(curr[1]) };
        for (0..4) |index| {
            if (neighbors[index] == null) continue;

            neighbors[index].?[0] += c[0];
            neighbors[index].?[1] += c[1];
        }

        return neighbors;
    }

    fn getInBounds(pos: [2]isize) ?[2]usize {
        if (pos[0] < 0 or pos[1] < 0) return null;
        if (pos[0] >= 4 or pos[1] >= 3) return null;

        return .{ @intCast(pos[0]), @intCast(pos[1]) };
    }
};

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?usize {
    var arena = std.heap.ArenaAllocator.init(this.allocator);
    defer arena.deinit();

    var num_pad = try NumPad.init(&arena);
    var dir_pad = try DirPad.init(&arena);
    var sum: usize = 0;

    var it = mem.splitSequence(u8, this.input, "\n");
    while (it.next()) |code| {
        if (code.len < 1) continue;
        const num = try std.fmt.parseInt(usize, code[0 .. code.len - 1], 10);
        const r1_inputs = try num_pad.sequenceToPath(code);
        var min_count: usize = std.math.maxInt(usize);
        for (r1_inputs.items) |r1_input| {
            const count = try dir_pad.countInstructions(r1_input, 2);
            if (count < min_count) min_count = count;
        }

        sum += num * min_count;
    }

    return sum;
}

pub fn part2(this: *const @This()) !?usize {
    var arena = std.heap.ArenaAllocator.init(this.allocator);
    defer arena.deinit();

    var num_pad = try NumPad.init(&arena);
    var dir_pad = try DirPad.init(&arena);
    var sum: usize = 0;

    var it = mem.splitSequence(u8, this.input, "\n");
    while (it.next()) |code| {
        if (code.len < 1) continue;
        const num = try std.fmt.parseInt(usize, code[0 .. code.len - 1], 10);
        const r1_inputs = try num_pad.sequenceToPath(code);
        var min_count: usize = std.math.maxInt(usize);
        for (r1_inputs.items) |r1_input| {
            const count = try dir_pad.countInstructions(r1_input, 25);
            if (count < min_count) min_count = count;
        }

        sum += num * min_count;
    }

    return sum;
}

test "sample input" {
    const allocator = std.testing.allocator;
    const input = "029A\n980A\n179A\n456A\n379A\n";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(126384, try problem.part1());
    try std.testing.expectEqual(154115708116294, try problem.part2());
}
