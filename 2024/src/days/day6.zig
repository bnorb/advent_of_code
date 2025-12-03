const std = @import("std");
const mem = std.mem;

const Set = std.AutoHashMap([2]isize, void);
const StateSet = std.AutoHashMap(struct { isize, isize, u8 }, void);

const ObstacleMap = std.AutoHashMap(isize, std.ArrayList(isize));

const Obstacles = struct {
    row_mapping: ObstacleMap,
    col_mapping: ObstacleMap,

    pub fn init(allocator: mem.Allocator, input: []const u8) !Obstacles {
        var row_mapping = ObstacleMap.init(allocator);
        var col_mapping = ObstacleMap.init(allocator);

        var it = mem.splitSequence(u8, input, "\n");

        var row: usize = 0;
        while (it.next()) |line| : (row += 1) {
            if (line.len < 1) {
                continue;
            }

            for (line, 0..) |cell, col| {
                if (cell == '#') {
                    try addVal(allocator, &row_mapping, @intCast(row), @intCast(col));
                    try addVal(allocator, &col_mapping, @intCast(col), @intCast(row));
                }
            }
        }

        return Obstacles{
            .row_mapping = row_mapping,
            .col_mapping = col_mapping,
        };
    }

    pub fn free(this: *@This()) void {
        freeMap(&this.row_mapping);
        freeMap(&this.col_mapping);
    }

    pub fn getInRow(this: *const @This(), row: isize, curr_col: isize, right: bool) ?[2]isize {
        const col = get(&this.row_mapping, row, curr_col, right);
        if (col) |c| {
            return .{ row, c };
        }

        return null;
    }

    pub fn getInCol(this: *const @This(), col: isize, curr_row: isize, down: bool) ?[2]isize {
        const row = get(&this.col_mapping, col, curr_row, down);
        if (row) |r| {
            return .{ r, col };
        }

        return null;
    }

    pub fn add(this: *@This(), allocator: mem.Allocator, row: isize, col: isize) !void {
        try addVal(allocator, &this.row_mapping, row, col);
        try addVal(allocator, &this.col_mapping, col, row);
    }

    pub fn remove(this: *@This(), row: isize, col: isize) !void {
        try removeVal(&this.row_mapping, row, col);
        try removeVal(&this.col_mapping, col, row);
    }

    fn get(map: *const ObstacleMap, from: isize, curr_to: isize, positive_dir: bool) ?isize {
        if (!map.contains(from)) return null;

        const list = map.get(from).?;
        var nearest: ?isize = null;
        var min_diff: isize = std.math.maxInt(isize);
        for (list.items) |to| {
            const diff = if (positive_dir) to - curr_to else curr_to - to;
            if (diff < 1) continue;
            if (min_diff < diff) continue;

            nearest = to;
            min_diff = diff;
        }

        return nearest;
    }

    fn freeMap(map: *ObstacleMap) void {
        defer map.deinit();

        var it = map.valueIterator();
        while (it.next()) |list| {
            defer list.deinit();
        }
    }

    fn addVal(allocator: mem.Allocator, map: *ObstacleMap, from: isize, to: isize) !void {
        var entry = try map.getOrPut(from);
        if (!entry.found_existing) {
            entry.value_ptr.* = std.ArrayList(isize).init(allocator);
        }

        try entry.value_ptr.append(to);
    }

    fn removeVal(map: *ObstacleMap, from: isize, to: isize) !void {
        var entry = try map.getOrPut(from);
        if (!entry.found_existing) {
            return;
        }

        for (0..entry.value_ptr.items.len) |index| {
            if (entry.value_ptr.items[index] == to) {
                _ = entry.value_ptr.swapRemove(index);
            }
        }
    }
};

const GuardArea = struct {
    width: isize,
    hegiht: isize,
    obstacles: Obstacles,
    visited: Set,
    states: StateSet,
    current: [2]isize,
    start: [2]isize,
    dir: u8 = 0, // UP: 0, RIGHT: 1, DOWN: 2, LEFT: 3
    start_dir: u8 = 0,

    pub fn init(allocator: mem.Allocator, dimensions: [2]usize, input: []const u8) !GuardArea {
        var it = mem.splitSequence(u8, input, "\n");

        var start: [2]isize = .{ 0, 0 };
        var index: usize = 0;
        while (it.next()) |line| : (index += 1) {
            if (line.len < 1) {
                continue;
            }

            for (line, 0..) |cell, col| {
                if (cell == '^') {
                    start[0] = @intCast(index);
                    start[1] = @intCast(col);
                }
            }
        }

        var visited = Set.init(allocator);
        try visited.put(start, undefined);

        var states = StateSet.init(allocator);
        try states.put(.{ start[0], start[1], 0 }, undefined);

        return GuardArea{
            .hegiht = @intCast(dimensions[0]),
            .width = @intCast(dimensions[1]),
            .obstacles = try Obstacles.init(allocator, input),
            .start = start,
            .current = .{ start[0], start[1] },
            .visited = visited,
            .states = states,
        };
    }

    pub fn free(this: *@This()) void {
        this.obstacles.free();
        this.visited.deinit();
        this.states.deinit();
    }

    pub fn reset(this: *@This()) !void {
        @memcpy(&this.current, &this.start);
        this.dir = 0;

        var it = this.visited.keyIterator();
        while (it.next()) |key| {
            this.visited.removeByPtr(key);
        }

        var sit = this.states.keyIterator();
        while (sit.next()) |key| {
            this.states.removeByPtr(key);
        }
    }

    pub fn walk(this: *@This(), save: bool) !bool {
        while (try this.move(save)) {
            const state = .{ this.current[0], this.current[1], this.dir };

            if (this.states.contains(state)) {
                return true;
            }

            try this.states.put(state, undefined);
        }

        return false;
    }

    fn move(this: *@This(), save: bool) !bool { // true continues
        const row = this.current[0];
        const col = this.current[1];
        const dir = this.dir;

        var obstacle: ?[2]isize = null;
        if (dir == 0 or dir == 2) {
            obstacle = this.obstacles.getInCol(col, row, dir == 2);
        } else {
            obstacle = this.obstacles.getInRow(row, col, dir == 1);
        }

        if (obstacle) |o| {
            this.updatePos(row, col, o);
        } else {
            this.updatePosExit(row, col);
        }

        if (save) {
            try this.saveVisited(dir, row, col);
        }

        return obstacle != null;
    }

    fn saveVisited(this: *@This(), og_dir: u8, og_row: isize, og_col: isize) !void {
        const start: usize = @intCast(switch (og_dir) {
            0 => this.current[0],
            1 => og_col,
            2 => og_row,
            3 => this.current[1],
            else => std.debug.panic("wtf is that dir? {d}\n", .{this.dir}),
        });

        const end: usize = @intCast(switch (og_dir) {
            0 => og_row,
            1 => this.current[1],
            2 => this.current[0],
            3 => og_col,
            else => std.debug.panic("wtf is that dir? {d}\n", .{this.dir}),
        });

        if (og_dir == 0 or og_dir == 2) {
            for (start..end + 1) |r| {
                try this.visited.put(.{ @intCast(r), og_col }, undefined);
            }
        } else {
            for (start..end + 1) |c| {
                try this.visited.put(.{ og_row, @intCast(c) }, undefined);
            }
        }
    }

    fn updatePos(this: *@This(), row: isize, col: isize, obstacle: [2]isize) void {
        this.current[0] = switch (this.dir) {
            1, 3 => row,
            0 => obstacle[0] + 1,
            2 => obstacle[0] - 1,
            else => std.debug.panic("wtf is that dir? {d}\n", .{this.dir}),
        };

        this.current[1] = switch (this.dir) {
            0, 2 => col,
            3 => obstacle[1] + 1,
            1 => obstacle[1] - 1,
            else => std.debug.panic("wtf is that dir? {d}\n", .{this.dir}),
        };

        this.dir = (this.dir + 1) % 4;
    }

    fn updatePosExit(this: *@This(), row: isize, col: isize) void {
        this.current[0] = switch (this.dir) {
            1, 3 => row,
            0 => 0,
            2 => this.hegiht - 1,
            else => std.debug.panic("wtf is that dir? {d}\n", .{this.dir}),
        };

        this.current[1] = switch (this.dir) {
            0, 2 => col,
            3 => 0,
            1 => this.width - 1,
            else => std.debug.panic("wtf is that dir? {d}\n", .{this.dir}),
        };
    }
};

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?u32 {
    const dimensions = this.getDimensions();
    var guard_area = try GuardArea.init(this.allocator, dimensions, this.input);
    defer guard_area.free();

    _ = try guard_area.walk(true);
    return guard_area.visited.count();
}

pub fn part2(this: *const @This()) !?i64 {
    const dimensions = this.getDimensions();
    var guard_area = try GuardArea.init(this.allocator, dimensions, this.input);
    defer guard_area.free();
    var count: u32 = 0;

    _ = try guard_area.walk(true);
    var visited_list: [][2]isize = try this.allocator.alloc([2]isize, @intCast(guard_area.visited.count()));
    defer this.allocator.free(visited_list);

    var it = guard_area.visited.keyIterator();
    var i: usize = 0;
    while (it.next()) |key| : (i += 1) {
        var cell: [2]isize = undefined;
        @memcpy(&cell, key);
        visited_list[i] = cell;
    }

    try guard_area.reset();

    for (visited_list) |curr| {
        const row = curr[0];
        const col = curr[1];

        if (row == guard_area.start[0] and col == guard_area.start[1]) {
            continue;
        }

        try guard_area.obstacles.add(this.allocator, row, col);

        if (try guard_area.walk(false)) {
            count += 1;
        }
        try guard_area.reset();

        try guard_area.obstacles.remove(row, col);
    }

    return count;
}

fn getDimensions(this: *const @This()) [2]usize {
    var it = mem.splitSequence(u8, this.input, "\n");

    var width: usize = 0;
    var height: usize = 0;

    while (it.next()) |line| {
        if (width == 0) {
            width = line.len;
        }

        if (line.len < 1) {
            continue;
        }

        height += 1;
    }

    return .{ height, width };
}

test "sample input" {
    const allocator = std.testing.allocator;
    const input = "....#.....\n.........#\n..........\n..#.......\n.......#..\n..........\n.#..^.....\n........#.\n#.........\n......#...";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(41, try problem.part1());
    try std.testing.expectEqual(6, try problem.part2());
}
