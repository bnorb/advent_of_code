const std = @import("std");
const mem = std.mem;

const DIRS: [4][2]isize = .{
    .{ -1, 0 },
    .{ 1, 0 },
    .{ 0, -1 },
    .{ 0, 1 },
};

const Map = std.AutoHashMap([2]usize, [2]usize);

const Track = struct {
    height: usize,
    width: usize,
    matrix: [][]bool,
    start: [2]usize,
    end: [2]usize,
    time_map: Map,

    pub fn init(allocator: mem.Allocator, input: []const u8) !Track {
        const dimensions = getDimensions(input);
        var matrix = try allocator.alloc([]bool, dimensions[0]);

        var start: [2]usize = .{ 0, 0 };
        var end: [2]usize = .{ 0, 0 };
        var it = mem.splitSequence(u8, input, "\n");
        var row: usize = 0;
        while (it.next()) |line| : (row += 1) {
            if (line.len < 1) continue;

            matrix[row] = try allocator.alloc(bool, dimensions[1]);
            for (line, 0..dimensions[1]) |char, col| {
                matrix[row][col] = if (char == '#') false else true;

                if (char == 'S') {
                    start = .{ row, col };
                }

                if (char == 'E') {
                    end = .{ row, col };
                }
            }
        }

        return Track{
            .height = dimensions[0],
            .width = dimensions[1],
            .matrix = matrix,
            .start = start,
            .end = end,
            .time_map = Map.init(allocator),
        };
    }

    pub fn free(this: *@This(), allocator: mem.Allocator) void {
        for (this.matrix) |row| {
            allocator.free(row);
        }

        allocator.free(this.matrix);
        this.time_map.deinit();
    }

    pub fn timeTrack(this: *@This()) !void {
        _ = try this.time(this.start, null, 0);
    }

    pub fn findCheats(this: *@This(), list: *std.ArrayList(usize), radius: isize) !void {
        try this.findCheat(this.start, null, list, radius);
    }

    fn findCheat(this: *@This(), curr: [2]usize, prev: ?[2]usize, list: *std.ArrayList(usize), radius: isize) !void {
        if (curr[0] == this.end[0] and curr[1] == this.end[1]) {
            return;
        }

        try this.addCheats(curr, radius, list);

        const next = this.getNext(curr, prev);
        try this.findCheat(next, curr, list, radius);
    }

    fn addCheats(this: *@This(), curr: [2]usize, radius: isize, list: *std.ArrayList(usize)) !void {
        const c: [2]isize = .{ @intCast(curr[0]), @intCast(curr[1]) };
        const curr_times = this.time_map.get(curr).?;

        var d_r: isize = -radius;
        while (d_r <= radius) : (d_r += 1) {
            const column_radius: isize = radius - @as(isize, @intCast(@abs(d_r)));
            var d_c: isize = -column_radius;
            while (d_c <= column_radius) : (d_c += 1) {
                if (d_r == 0 and d_c == 0) continue;

                const pot_pos: [2]isize = .{ c[0] + d_r, c[1] + d_c };
                if (!this.isInBounds(pot_pos)) continue;

                const pos: [2]usize = .{ @intCast(pot_pos[0]), @intCast(pot_pos[1]) };
                if (!this.isFree(pos)) continue;

                const pos_times = this.time_map.get(pos).?;
                if (pos_times[0] <= curr_times[0]) continue;

                const time_saved = curr_times[1] - pos_times[1];
                const cheat_time = calcManhattan(curr, pos);
                if (cheat_time > time_saved) continue;

                try list.append(time_saved - cheat_time);
            }
        }
    }

    fn calcManhattan(p1: [2]usize, p2: [2]usize) usize {
        const dr: usize = if (p2[0] >= p1[0]) p2[0] - p1[0] else p1[0] - p2[0];
        const dc: usize = if (p2[1] >= p1[1]) p2[1] - p1[1] else p1[1] - p2[1];

        return dr + dc;
    }

    fn time(this: *@This(), curr: [2]usize, prev: ?[2]usize, start_elapsed: usize) !usize {
        if (curr[0] == this.end[0] and curr[1] == this.end[1]) {
            try this.time_map.put(curr, .{ start_elapsed, 0 });
            return 1;
        }

        const next = this.getNext(curr, prev);
        const end_left = try this.time(next, curr, start_elapsed + 1);
        try this.time_map.put(curr, .{ start_elapsed, end_left });

        return end_left + 1;
    }

    fn getDimensions(input: []const u8) [2]usize {
        var it = mem.splitSequence(u8, input, "\n");

        var width: usize = 0;
        var height: usize = 0;

        while (it.next()) |line| {
            if (line.len < 1) continue;

            if (width == 0) {
                width = line.len;
            }

            height += 1;
        }

        return .{ height, width };
    }

    fn printMap(this: *const @This()) void {
        std.debug.print("===================================================\n", .{});
        for (this.matrix) |row| {
            for (row) |cell| {
                const c: u8 = if (cell) '.' else '#';
                std.debug.print("{c}", .{c});
            }

            std.debug.print("\n", .{});
        }
        std.debug.print("===================================================\n", .{});
    }

    fn getNext(this: *const @This(), curr: [2]usize, prev: ?[2]usize) [2]usize {
        const c: [2]isize = .{ @intCast(curr[0]), @intCast(curr[1]) };
        for (DIRS) |dir| {
            const pos: [2]usize = .{ @intCast(c[0] + dir[0]), @intCast(c[1] + dir[1]) };
            if (!this.isFree(pos)) continue;
            if (prev) |pr| {
                if (pr[0] == pos[0] and pr[1] == pos[1]) continue;
            }

            return pos;
        }

        unreachable;
    }

    fn isFree(this: *const @This(), pos: [2]usize) bool {
        return this.matrix[pos[0]][pos[1]];
    }

    fn isInBounds(this: *const @This(), pos: [2]isize) bool {
        if (pos[0] < 0 or pos[1] < 0) return false;
        if (pos[0] >= this.height or pos[1] >= this.width) return false;

        return true;
    }
};

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?u32 {
    var track = try Track.init(this.allocator, this.input);
    defer track.free(this.allocator);

    try track.timeTrack();

    var cheat_saves = std.ArrayList(usize).init(this.allocator);
    defer cheat_saves.deinit();

    try track.findCheats(&cheat_saves, 2);

    var count: u32 = 0;
    for (cheat_saves.items) |save| {
        if (save >= 100) {
            count += 1;
        }
    }

    return count;
}

pub fn part2(this: *const @This()) !?i64 {
    var track = try Track.init(this.allocator, this.input);
    defer track.free(this.allocator);

    try track.timeTrack();

    var cheat_saves = std.ArrayList(usize).init(this.allocator);
    defer cheat_saves.deinit();

    try track.findCheats(&cheat_saves, 20);

    var count: u32 = 0;
    for (cheat_saves.items) |save| {
        if (save >= 100) {
            count += 1;
        }
    }

    return count;
}

test "sample input" {
    const allocator = std.testing.allocator;
    const input = "###############\n#...#...#.....#\n#.#.#.#.#.###.#\n#S#...#.#.#...#\n#######.#.#.###\n#######.#.#...#\n#######.#.###.#\n###..E#...#...#\n###.#######.###\n#...###...#...#\n#.#####.#.###.#\n#.#...#.#.#...#\n#.#.#.#.#.#.###\n#...#...#...###\n###############\n";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(null, try problem.part1());
}
