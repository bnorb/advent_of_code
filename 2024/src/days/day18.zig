const std = @import("std");
const mem = std.mem;

const DIRS: [4][2]isize = .{
    .{ -1, 0 },
    .{ 1, 0 },
    .{ 0, -1 },
    .{ 0, 1 },
};

const Queue = std.DoublyLinkedList([3]usize);
const Set = std.AutoHashMap([2]usize, void);
const FCache = std.AutoHashMap([2]usize, usize);

const Maze = struct {
    height: usize,
    width: usize,
    matrix: [][]bool,
    start: [2]usize,
    end: [2]usize,
    arena: *std.heap.ArenaAllocator,

    pub fn init(arena: *std.heap.ArenaAllocator, input: []const u8, byte_limit: usize, height: usize, width: usize) !Maze {
        const allocator = arena.allocator();
        var matrix = try allocator.alloc([]bool, height);

        for (0..height) |row| {
            matrix[row] = try allocator.alloc(bool, width);
            for (0..width) |col| {
                matrix[row][col] = true;
            }
        }

        var maze = Maze{
            .height = height,
            .width = width,
            .matrix = matrix,
            .start = .{ 0, 0 },
            .end = .{ height - 1, width - 1 },
            .arena = arena,
        };

        var it = mem.splitSequence(u8, input, "\n");
        var bytes_fell: usize = 0;
        while (it.next()) |line| : (bytes_fell += 1) {
            if (bytes_fell >= byte_limit) break;
            try maze.addByte(line);
        }

        return maze;
    }

    pub fn addByte(this: *@This(), line: []const u8) !void {
        const coords = try parseCoords(line);
        this.matrix[coords[0]][coords[1]] = false;
    }

    pub fn findPath(this: *@This()) !?usize {
        const allocator = this.arena.allocator();
        var queue = Queue{};
        var visited = Set.init(allocator);
        defer visited.deinit();

        var startNode = try allocator.create(Queue.Node);
        startNode.data = .{ this.start[0], this.start[1], 0 };
        queue.append(startNode);

        while (queue.popFirst()) |curr| {
            const pos = .{ curr.data[0], curr.data[1] };
            const steps = curr.data[2];
            if (pos[0] == this.end[0] and pos[1] == this.end[1]) {
                return steps;
            }

            const neighbors = getNeighbors(pos);

            for (neighbors) |neighbor| {
                if (!this.isInBounds(neighbor)) continue;

                const n: [2]usize = .{ @intCast(neighbor[0]), @intCast(neighbor[1]) };

                if (!this.isFree(n)) continue;
                if (visited.contains(n)) continue;

                try visited.put(.{ n[0], n[1] }, undefined);

                var node = try allocator.create(Queue.Node);
                node.data = .{ n[0], n[1], steps + 1 };
                queue.append(node);
            }
        }

        return null;
    }

    fn parseCoords(line: []const u8) ![2]usize {
        var coords_it = mem.splitScalar(u8, line, ',');
        const x = try std.fmt.parseInt(usize, coords_it.next().?, 10);
        const y = try std.fmt.parseInt(usize, coords_it.next().?, 10);

        return .{ y, x };
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

    fn getNeighbors(curr: [2]usize) [4][2]isize {
        var neighbors: [4][2]isize = DIRS;
        const c: [2]isize = .{ @intCast(curr[0]), @intCast(curr[1]) };
        for (0..4) |index| {
            neighbors[index][0] += c[0];
            neighbors[index][1] += c[1];
        }

        return neighbors;
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
width: usize = 71,
height: usize = 71,
byte_limit: usize = 1024,

pub fn part1(this: *const @This()) !?usize {
    var arena = std.heap.ArenaAllocator.init(this.allocator);
    defer arena.deinit();

    var maze = try Maze.init(&arena, this.input, this.byte_limit, this.height, this.width);

    return (try maze.findPath()).?;
}

pub fn part2(this: *const @This()) !?[]const u8 {
    var arena = std.heap.ArenaAllocator.init(this.allocator);
    defer arena.deinit();

    var maze = try Maze.init(&arena, this.input, this.byte_limit, this.height, this.width);
    var it = mem.splitSequence(u8, this.input, "\n");
    for (0..this.byte_limit) |_| {
        _ = it.next();
    }

    while (it.next()) |line| {
        try maze.addByte(line);
        const steps = try maze.findPath();
        if (steps == null) {
            return line;
        }
    }

    return null;
}

test "sample input" {
    const allocator = std.testing.allocator;
    const input = "5,4\n4,2\n4,5\n3,0\n2,1\n6,3\n2,4\n1,5\n0,6\n3,3\n2,6\n5,1\n1,2\n5,5\n2,5\n6,5\n1,4\n0,4\n6,4\n1,1\n6,1\n1,0\n0,5\n1,6\n2,0\n";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
        .width = 7,
        .height = 7,
        .byte_limit = 12,
    };

    try std.testing.expectEqual(22, try problem.part1());
    try std.testing.expectEqualStrings("6,1", (try problem.part2()).?);
}
