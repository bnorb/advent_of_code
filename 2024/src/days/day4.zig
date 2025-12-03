const std = @import("std");
const mem = std.mem;

const DIRS: [8][2]isize = .{
    .{ -1, -1 },
    .{ -1, 0 },
    .{ -1, 1 },
    .{ 0, -1 },
    .{ 0, 1 },
    .{ 1, -1 },
    .{ 1, 0 },
    .{ 1, 1 },
};

const WordSearch = struct {
    matrix: [][]u8,
    starts: std.ArrayList([2]usize),
    xmas_count: u32 = 0,

    pub fn init(allocator: mem.Allocator, dimensions: [2]usize, input: []const u8) !WordSearch {
        var matrix: [][]u8 = undefined;
        matrix = try allocator.alloc([]u8, dimensions[0]);

        var it = mem.splitSequence(u8, input, "\n");

        var index: usize = 0;
        while (it.next()) |line| : (index += 1) {
            if (line.len < 1) {
                continue;
            }

            matrix[index] = try allocator.alloc(u8, dimensions[1]);
            @memcpy(matrix[index], line);
        }

        return WordSearch{
            .matrix = matrix,
            .starts = std.ArrayList([2]usize).init(allocator),
        };
    }

    pub fn free(this: *@This(), allocator: mem.Allocator) void {
        this.starts.deinit();

        for (this.matrix) |row| {
            allocator.free(row);
        }

        allocator.free(this.matrix);
    }

    pub fn countXmas(this: *@This()) !u32 {
        try this.getPotentialStarts('X');

        for (this.starts.items) |start| {
            for (DIRS) |dir| {
                this.searchXmas(start, 4, dir);
            }
        }

        return this.xmas_count;
    }

    pub fn countCrossMas(this: *@This()) !u32 {
        try this.getPotentialStarts('A');

        for (this.starts.items) |start| {
            const row = start[0];
            const col = start[1];

            if (row < 1 or row > this.matrix.len - 2) {
                continue;
            }

            if (col < 1 or col > this.matrix[0].len - 2) {
                continue;
            }

            const u_l = this.matrix[row - 1][col - 1];
            const u_r = this.matrix[row - 1][col + 1];
            const l_l = this.matrix[row + 1][col - 1];
            const l_r = this.matrix[row + 1][col + 1];

            if (((u_l == 'M' and l_r == 'S') or (u_l == 'S' and l_r == 'M')) and ((u_r == 'M' and l_l == 'S') or (u_r == 'S' and l_l == 'M'))) {
                this.xmas_count += 1;
            }
        }

        return this.xmas_count;
    }

    fn getPotentialStarts(this: *@This(), target: u8) !void {
        try this.starts.resize(0);

        for (this.matrix, 0..) |row, row_index| {
            for (row, 0..) |cell, col_index| {
                if (cell == target) {
                    try this.starts.append(.{ row_index, col_index });
                }
            }
        }
    }

    fn searchXmas(this: *@This(), curr: [2]usize, remaining_chars: u8, dir: [2]isize) void {
        const row = curr[0];
        const col = curr[1];

        if (!isValidChar(this.matrix[row][col], remaining_chars)) {
            return;
        }

        if (remaining_chars == 1) {
            this.xmas_count += 1;
            return;
        }

        const next: [2]isize = .{ @as(isize, @intCast(row)) + dir[0], @as(isize, @intCast(col)) + dir[1] };
        if (!this.isValidCell(next)) {
            return;
        }

        this.searchXmas(.{ @intCast(next[0]), @intCast(next[1]) }, remaining_chars - 1, dir);
    }

    fn isValidCell(this: *@This(), cell: [2]isize) bool {
        if (cell[0] < 0 or cell[0] >= this.matrix.len) {
            return false;
        }

        if (cell[1] < 0 or cell[1] >= this.matrix[0].len) {
            return false;
        }

        return true;
    }

    fn isValidChar(char: u8, remaining_chars: u8) bool {
        return switch (remaining_chars) {
            4 => char == 'X',
            3 => char == 'M',
            2 => char == 'A',
            1 => char == 'S',
            else => false,
        };
    }

    fn getNeighbors(curr: [2]usize) [8][2]isize {
        const row: isize = @intCast(curr[0]);
        const col: isize = @intCast(curr[1]);

        return .{
            .{ row - 1, col - 1 },
            .{ row - 1, col },
            .{ row - 1, col + 1 },
            .{ row, col - 1 },
            .{ row, col + 1 },
            .{ row + 1, col - 1 },
            .{ row + 1, col },
            .{ row + 1, col + 1 },
        };
    }
};

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?u32 {
    const dimensions = this.getDimensions();
    var word_search = try WordSearch.init(this.allocator, dimensions, this.input);
    defer word_search.free(this.allocator);

    return try word_search.countXmas();
}

pub fn part2(this: *const @This()) !?u32 {
    const dimensions = this.getDimensions();
    var word_search = try WordSearch.init(this.allocator, dimensions, this.input);
    defer word_search.free(this.allocator);

    return try word_search.countCrossMas();
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
    const input = "MMMSXXMASM\nMSAMXMSMSA\nAMXSXMAAMM\nMSAMASMSMX\nXMASAMXAMM\nXXAMMXXAMA\nSMSMSASXSS\nSAXAMASAAA\nMAMMMXMMMM\nMXMXAXMASX";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(18, try problem.part1());
    try std.testing.expectEqual(9, try problem.part2());
}
