const std = @import("std");
const mem = std.mem;

const DIRS: [4][2]isize = .{
    .{ -1, 0 },
    .{ 1, 0 },
    .{ 0, -1 },
    .{ 0, 1 },
};

const Set = std.AutoHashMap([2]usize, void);

const Warehouse = struct {
    width: usize,
    height: usize,
    curr: [2]usize,
    walls: Set,
    boxes: Set,
    moves: []const u8,

    pub fn init(allocator: mem.Allocator, input: []const u8) !Warehouse {
        var parts = mem.splitSequence(u8, input, "\n\n");
        const map = parts.next().?;
        const moves = parts.next().?;

        var height: usize = 0;
        var width: usize = 0;
        var walls = Set.init(allocator);
        var boxes = Set.init(allocator);
        var start: [2]usize = .{ 0, 0 };
        var row: usize = 0;

        var it = mem.splitSequence(u8, map, "\n");
        while (it.next()) |line| : (row += 1) {
            if (line.len < 1) continue;
            if (width == 0) {
                width = line.len;
            }
            height += 1;

            for (line, 0..line.len) |char, col| {
                if (char == '@') {
                    start[0] = row;
                    start[1] = col;
                } else if (char == '#') {
                    try walls.put(.{ row, col }, undefined);
                } else if (char == 'O') {
                    try boxes.put(.{ row, col }, undefined);
                }
            }
        }

        return Warehouse{
            .width = width,
            .height = height,
            .curr = start,
            .walls = walls,
            .boxes = boxes,
            .moves = moves,
        };
    }

    pub fn free(this: *@This()) void {
        this.walls.deinit();
        this.boxes.deinit();
    }

    pub fn simulate(this: *@This()) !void {
        for (this.moves) |move| {
            if (getDir(move)) |dir| {
                const next = getNext(this.curr, dir);
                if (this.walls.contains(next)) {
                    continue;
                } else if (this.boxes.contains(next)) {
                    if (!try this.moveBoxes(next, dir)) {
                        continue;
                    }
                }

                this.curr = next;
            }
        }
    }

    pub fn calcGPS(this: *const @This()) u64 {
        var sum: u64 = 0;
        var it = this.boxes.keyIterator();
        while (it.next()) |key| {
            sum += (100 * key[0]) + key[1];
        }

        return sum;
    }

    pub fn printMap(this: *const @This()) void {
        std.debug.print("===============================================\n", .{});
        for (0..this.height) |row| {
            for (0..this.width) |col| {
                var char: u8 = '.';
                if (this.boxes.contains(.{ row, col })) {
                    char = 'O';
                } else if (this.walls.contains(.{ row, col })) {
                    char = '#';
                } else if (this.curr[0] == row and this.curr[1] == col) {
                    char = '@';
                }

                std.debug.print("{c}", .{char});
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("===============================================\n", .{});
    }

    fn moveBoxes(this: *@This(), first_box: [2]usize, dir: [2]isize) !bool {
        var empty_cell: ?[2]usize = null;
        var curr = first_box;
        while (!this.walls.contains(curr)) : (curr = getNext(curr, dir)) {
            if (!this.boxes.contains(curr)) {
                empty_cell = curr;
                break;
            }
        }

        if (empty_cell) |cell| {
            _ = this.boxes.remove(first_box);
            try this.boxes.put(cell, undefined);

            return true;
        }

        return false;
    }

    fn getDir(move: u8) ?[2]isize {
        const dir_index: usize = switch (move) {
            '^' => 0,
            'v' => 1,
            '<' => 2,
            '>' => 3,
            else => 4,
        };

        if (dir_index > 3) return null;

        return DIRS[dir_index];
    }

    fn getNext(curr: [2]usize, dir: [2]isize) [2]usize {
        const i_curr: [2]isize = .{ @intCast(curr[0]), @intCast(curr[1]) };
        const next: [2]isize = .{ i_curr[0] + dir[0], i_curr[1] + dir[1] };

        return .{ @intCast(next[0]), @intCast(next[1]) };
    }
};

const BigWarehouse = struct {
    width: usize,
    height: usize,
    curr: [2]usize,
    walls: Set,
    boxes: Set,
    moves: []const u8,

    pub fn init(allocator: mem.Allocator, warehouse: *Warehouse) !BigWarehouse {
        const start: [2]usize = .{ warehouse.curr[0], warehouse.curr[1] * 2 };

        var walls = Set.init(allocator);
        var boxes = Set.init(allocator);

        var it = warehouse.walls.keyIterator();
        while (it.next()) |key| {
            try walls.put(.{ key[0], key[1] * 2 }, undefined);
        }

        it = warehouse.boxes.keyIterator();
        while (it.next()) |key| {
            try boxes.put(.{ key[0], key[1] * 2 }, undefined);
        }

        return BigWarehouse{
            .width = warehouse.width * 2,
            .height = warehouse.height,
            .walls = walls,
            .boxes = boxes,
            .moves = warehouse.moves,
            .curr = start,
        };
    }

    pub fn free(this: *@This()) void {
        this.walls.deinit();
        this.boxes.deinit();
    }

    pub fn printMap(this: *const @This()) void {
        std.debug.print("===============================================\n", .{});
        for (0..this.height) |row| {
            var col: usize = 0;
            while (col < this.width) {
                if (this.boxes.contains(.{ row, col })) {
                    std.debug.print("[]", .{});
                    col += 2;
                } else if (this.walls.contains(.{ row, col })) {
                    std.debug.print("##", .{});
                    col += 2;
                } else if (this.curr[0] == row and this.curr[1] == col) {
                    std.debug.print("@", .{});
                    col += 1;
                } else {
                    std.debug.print(".", .{});
                    col += 1;
                }
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("===============================================\n", .{});
    }

    pub fn simulate(this: *@This()) !void {
        for (this.moves) |move| {
            if (getDir(move)) |dir| {
                const next = getNext(this.curr, dir);
                if (getCoord(&this.walls, next)) |_| {
                    continue;
                }

                if (getCoord(&this.boxes, next)) |box| {
                    if (!try this.moveBoxes(box, dir)) {
                        continue;
                    }
                }

                this.curr = next;
            }
        }
    }

    pub fn getCoord(set: *Set, curr: [2]usize) ?[2]usize {
        if (set.contains(curr)) {
            return curr;
        }

        if (set.getKey(.{ curr[0], curr[1] - 1 })) |key| {
            return key;
        }

        return null;
    }

    pub fn calcGPS(this: *const @This()) u64 {
        var sum: u64 = 0;
        var it = this.boxes.keyIterator();
        while (it.next()) |key| {
            sum += (100 * key[0]) + key[1];
        }

        return sum;
    }

    fn moveBoxTo(this: *@This(), from: [2]usize, to: [2]usize) !void {
        _ = this.boxes.remove(from);
        try this.boxes.put(to, undefined);
    }

    fn moveHorizontally(this: *@This(), curr: [2]usize, dir: [2]isize) !bool {
        const next = getNext(curr, dir);
        var to_check = next;
        if (dir[1] == 1) {
            to_check = getNext(next, dir);
        }

        if (getCoord(&this.walls, to_check)) |_| {
            return false;
        }

        if (getCoord(&this.boxes, to_check)) |box| {
            const moved = try this.moveHorizontally(box, dir);
            if (moved) {
                try this.moveBoxTo(curr, next);
            }

            return moved;
        }

        try this.moveBoxTo(curr, next);
        return true;
    }

    fn moveVertically(this: *@This(), curr: [2]usize, dir: [2]isize, do_move: bool) !bool {
        const left = getNext(curr, dir);
        const right = getNext(.{ curr[0], curr[1] + 1 }, dir);

        if (getCoord(&this.walls, left)) |_| {
            return false;
        }

        if (getCoord(&this.walls, right)) |_| {
            return false;
        }

        const left_box = getCoord(&this.boxes, left);
        const right_box = getCoord(&this.boxes, right);

        if (left_box == null and right_box == null) {
            if (do_move) try this.moveBoxTo(curr, left);
            return true;
        }

        if (left_box != null and right_box != null and left_box.?[1] == right_box.?[1]) {
            const moved = try this.moveVertically(left_box.?, dir, do_move);
            if (moved) {
                if (do_move) try this.moveBoxTo(curr, left);
            }

            return moved;
        }

        var left_can_move: ?bool = null;
        var right_can_move: ?bool = null;

        if (left_box) |box| {
            left_can_move = try this.moveVertically(box, dir, false);
        }

        if (right_box) |box| {
            right_can_move = try this.moveVertically(box, dir, false);
        }

        if (left_can_move != null and right_can_move != null) {
            const both_can_move = left_can_move.? and right_can_move.?;
            if (both_can_move) {
                _ = try this.moveVertically(left_box.?, dir, do_move);
                _ = try this.moveVertically(right_box.?, dir, do_move);

                if (do_move) try this.moveBoxTo(curr, left);
            }

            return both_can_move;
        }

        if (left_can_move) |can_move| {
            if (can_move) {
                _ = try this.moveVertically(left_box.?, dir, do_move);
                if (do_move) try this.moveBoxTo(curr, left);
            }

            return can_move;
        }

        if (right_can_move) |can_move| {
            if (can_move) {
                _ = try this.moveVertically(right_box.?, dir, do_move);
                if (do_move) try this.moveBoxTo(curr, left);
            }
            return can_move;
        }

        return false;
    }

    fn moveBoxes(this: *@This(), first_box: [2]usize, dir: [2]isize) !bool {
        if (dir[0] == 0) {
            return try this.moveHorizontally(first_box, dir);
        } else {
            if (try this.moveVertically(first_box, dir, false)) {
                return try this.moveVertically(first_box, dir, true);
            }

            return false;
        }
    }

    fn getDir(move: u8) ?[2]isize {
        const dir_index: usize = switch (move) {
            '^' => 0,
            'v' => 1,
            '<' => 2,
            '>' => 3,
            else => 4,
        };

        if (dir_index > 3) return null;

        return DIRS[dir_index];
    }

    fn getNext(curr: [2]usize, dir: [2]isize) [2]usize {
        const i_curr: [2]isize = .{ @intCast(curr[0]), @intCast(curr[1]) };
        const next: [2]isize = .{ i_curr[0] + dir[0], i_curr[1] + dir[1] };

        return .{ @intCast(next[0]), @intCast(next[1]) };
    }
};

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?u64 {
    var warehouse = try Warehouse.init(this.allocator, this.input);
    defer warehouse.free();

    try warehouse.simulate();

    return warehouse.calcGPS();
}

pub fn part2(this: *const @This()) !?u64 {
    var warehouse = try Warehouse.init(this.allocator, this.input);
    defer warehouse.free();
    var big_warehouse = try BigWarehouse.init(this.allocator, &warehouse);
    defer big_warehouse.free();

    try big_warehouse.simulate();

    return big_warehouse.calcGPS();
}

test "sample input" {
    const allocator = std.testing.allocator;
    const input = "##########\n#..O..O.O#\n#......O.#\n#.OO..O.O#\n#..O@..O.#\n#O#..O...#\n#O..O..O.#\n#.OO.O.OO#\n#....O...#\n##########\n\n<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^\nvvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v\n><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<\n<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^\n^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><\n^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^\n>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^\n<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>\n^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>\nv^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^\n";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(10092, try problem.part1());
    try std.testing.expectEqual(9021, try problem.part2());
}
