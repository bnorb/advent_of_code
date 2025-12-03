const std = @import("std");
const mem = std.mem;

const DIRS: [4][2]isize = .{
    .{ -1, 0 },
    .{ 1, 0 },
    .{ 0, -1 },
    .{ 0, 1 },
};

const Ends = std.AutoHashMap([2]usize, void);

const Cache = std.AutoHashMap([2]usize, std.ArrayList([2]usize));
const RatingsCache = std.AutoHashMap([2]usize, u32);

const Map = struct {
    height: usize,
    width: usize,
    matrix: [][]u8,
    starts: [][2]usize,
    cache: Cache,
    ratings_cache: RatingsCache,

    pub fn init(allocator: mem.Allocator, input: []const u8) !Map {
        const dimensions = getDimensions(input);
        var matrix: [][]u8 = try allocator.alloc([]u8, dimensions[0]);
        var starts: [][2]usize = try allocator.alloc([2]usize, dimensions[2]);

        var it = mem.splitSequence(u8, input, "\n");

        var index: usize = 0;
        var start_index: usize = 0;
        while (it.next()) |line| : (index += 1) {
            if (line.len < 1) {
                continue;
            }

            matrix[index] = try allocator.alloc(u8, dimensions[1]);

            for (line, 0..) |char, col| {
                matrix[index][col] = char - 48;

                if (char == '0') {
                    starts[start_index] = .{ index, col };
                    start_index += 1;
                }
            }
        }

        return Map{
            .height = dimensions[0],
            .width = dimensions[1],
            .matrix = matrix,
            .starts = starts,
            .cache = Cache.init(allocator),
            .ratings_cache = RatingsCache.init(allocator),
        };
    }

    pub fn free(this: *@This(), allocator: mem.Allocator) void {
        allocator.free(this.starts);
        for (this.matrix) |row| {
            allocator.free(row);
        }

        allocator.free(this.matrix);

        var it = this.cache.valueIterator();
        while (it.next()) |value| {
            value.deinit();
        }

        this.cache.deinit();
        this.ratings_cache.deinit();
    }

    pub fn printMap(this: *const @This()) void {
        std.debug.print("\n==================\n", .{});
        for (this.matrix) |row| {
            for (row) |cell| {
                std.debug.print("{d}", .{cell});
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("==================\n", .{});
    }

    pub fn sumTrailHeads(this: *@This(), allocator: mem.Allocator) !u32 {
        var sum: u32 = 0;
        for (this.starts) |start| {
            var parent_ends = Ends.init(allocator);
            defer parent_ends.deinit();

            try this.checkTrail(allocator, start, &parent_ends);
            sum += parent_ends.count();
        }

        return sum;
    }

    pub fn sumRatings(this: *@This()) !u32 {
        var sum: u32 = 0;
        for (this.starts) |start| {
            sum += try this.checkTrailRating(start);
        }

        return sum;
    }

    fn checkTrail(this: *@This(), allocator: mem.Allocator, curr: [2]usize, parent_ends: *Ends) !void {
        const row = curr[0];
        const col = curr[1];

        if (this.matrix[row][col] == 9) {
            try parent_ends.put(.{ row, col }, undefined);
            return;
        }

        if (this.cache.get(curr)) |cached| {
            for (cached.items) |coords| {
                try parent_ends.put(.{ coords[0], coords[1] }, undefined);
            }
            return;
        }

        var ends = Ends.init(allocator);
        defer ends.deinit();

        for (DIRS) |dir| {
            if (this.getValidNextCell(row, col, dir)) |next| {
                if (this.matrix[row][col] + 1 == this.matrix[next[0]][next[1]]) {
                    try this.checkTrail(allocator, next, &ends);
                }
            }
        }

        var list = std.ArrayList([2]usize).init(allocator);
        var it = ends.keyIterator();
        while (it.next()) |key| {
            try list.append(.{ key[0], key[1] });
            try parent_ends.put(.{ key[0], key[1] }, undefined);
        }

        try this.cache.put(curr, list);
    }

    fn checkTrailRating(this: *@This(), curr: [2]usize) !u32 {
        const row = curr[0];
        const col = curr[1];

        if (this.matrix[row][col] == 9) {
            return 1;
        }

        if (this.ratings_cache.get(curr)) |cached| {
            return cached;
        }

        var sum: u32 = 0;
        for (DIRS) |dir| {
            if (this.getValidNextCell(row, col, dir)) |next| {
                if (this.matrix[row][col] + 1 == this.matrix[next[0]][next[1]]) {
                    sum += try this.checkTrailRating(next);
                }
            }
        }

        try this.ratings_cache.put(curr, sum);

        return sum;
    }

    fn getValidNextCell(this: *const @This(), row: usize, col: usize, dir: [2]isize) ?[2]usize {
        var r: isize = @intCast(row);
        var c: isize = @intCast(col);

        r += dir[0];
        c += dir[1];

        if (r < 0 or c < 0) {
            return null;
        }

        const next: [2]usize = .{ @intCast(r), @intCast(c) };
        if (next[0] >= this.height or next[1] >= this.width) {
            return null;
        }

        return next;
    }

    fn getDimensions(input: []const u8) [3]usize {
        var it = mem.splitSequence(u8, input, "\n");

        var width: usize = 0;
        var height: usize = 0;
        var start_count: usize = 0;

        while (it.next()) |line| {
            if (width == 0) {
                width = line.len;
            }

            if (line.len < 1) {
                continue;
            }

            for (line) |char| {
                if (char == '0') {
                    start_count += 1;
                }
            }

            height += 1;
        }

        return .{ height, width, start_count };
    }
};

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?u32 {
    var map = try Map.init(this.allocator, this.input);
    defer map.free(this.allocator);

    return try map.sumTrailHeads(this.allocator);
}

pub fn part2(this: *const @This()) !?u32 {
    var map = try Map.init(this.allocator, this.input);
    defer map.free(this.allocator);

    return try map.sumRatings();
}

test "sample input" {
    const allocator = std.testing.allocator;
    const input = "89010123\n78121874\n87430965\n96549874\n45678903\n32019012\n01329801\n10456732\n";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(36, try problem.part1());
    try std.testing.expectEqual(81, try problem.part2());
}
