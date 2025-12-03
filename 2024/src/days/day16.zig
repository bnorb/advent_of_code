const std = @import("std");
const mem = std.mem;

const Dir = enum { N, E, S, W };

const Key = [2]usize;
const FCache = std.AutoHashMap(struct { usize, usize, Dir }, usize);
const Visited = std.AutoHashMap([2]usize, void);

fn compareNodes(_: void, a: *Node, b: *Node) std.math.Order {
    if (a.f < b.f) return std.math.Order.lt;
    if (a.f > b.f) return std.math.Order.gt;
    return std.math.Order.eq;
}

const Queue = std.PriorityQueue(*Node, void, compareNodes);

const Node = struct {
    pos: [2]usize,
    dir: Dir,
    g: usize,
    h: usize,
    f: usize,
    parent: ?*Node,
};

const Maze = struct {
    height: usize,
    width: usize,
    matrix: [][]bool,
    start: [2]usize,
    end: [2]usize,
    arena: *std.heap.ArenaAllocator,

    pub fn init(arena: *std.heap.ArenaAllocator, input: []const u8) !Maze {
        const dimensions = getDimensions(input);
        const allocator = arena.allocator();
        var matrix = try allocator.alloc([]bool, dimensions[0]);
        var it = mem.splitSequence(u8, input, "\n");
        var row: usize = 0;

        var start: [2]usize = .{ 0, 0 };
        var end: [2]usize = .{ 0, 0 };
        while (it.next()) |line| : (row += 1) {
            if (line.len < 1) continue;

            matrix[row] = try allocator.alloc(bool, dimensions[1]);
            for (line, 0..dimensions[1]) |char, col| {
                matrix[row][col] = switch (char) {
                    '#' => false,
                    '.' => true,
                    'S' => blk: {
                        start = .{ row, col };
                        break :blk true;
                    },
                    'E' => blk: {
                        end = .{ row, col };
                        break :blk true;
                    },
                    else => unreachable,
                };
            }
        }

        return Maze{
            .height = dimensions[0],
            .width = dimensions[1],
            .matrix = matrix,
            .start = start,
            .end = end,
            .arena = arena,
        };
    }

    pub fn aStar(this: *const @This(), visited: ?*Visited) !?*Node {
        const allocator = this.arena.allocator();
        var open_list = Queue.init(allocator, undefined);
        defer open_list.deinit();

        var closed_list = std.ArrayList(*Node).init(allocator);
        defer closed_list.deinit();

        var open_cache = FCache.init(allocator);
        defer open_cache.deinit();

        var closed_cache = FCache.init(allocator);
        defer closed_cache.deinit();

        const start_node = try this.makeNode(this.start, Dir.E, 0, 0, null);
        try open_list.add(start_node);

        var lowest_score: ?usize = null;

        while (open_list.removeOrNull()) |node| {
            const node_cache_key = .{ node.pos[0], node.pos[1], node.dir };
            _ = open_cache.remove(node_cache_key);

            const neighbors: [3][2]usize = .{ getForward(node.pos, node.dir), getLeft(node.pos, node.dir), getRight(node.pos, node.dir) };
            const next_dirs: [3]Dir = .{ node.dir, turnLeft(node.dir), turnRight(node.dir) };
            const distances: [3]usize = .{ 1, 1001, 1001 };
            for (neighbors, 0..3) |neighbor, i| {
                if (!this.isFree(neighbor)) continue;

                const pos = neighbor;
                const dir = next_dirs[i];
                const g = node.g + distances[i];
                const h = getHeuristic(pos, this.end);

                const new_node = try this.makeNode(pos, dir, g, h, node);
                if (pos[0] == this.end[0] and pos[1] == this.end[1]) {
                    if (visited == null) return new_node;

                    if (lowest_score) |ls| {
                        if (new_node.g > ls) return null;
                    } else {
                        lowest_score = new_node.g;
                    }

                    try putPathIntoVisited(new_node, visited.?);
                    continue;
                }

                const cache_key = .{ pos[0], pos[1], dir };
                var skip = false;
                if (open_cache.get(cache_key)) |open_f| {
                    if (open_f < new_node.f) {
                        skip = true;
                    }
                }

                if (closed_cache.get(cache_key)) |closed_f| {
                    if (closed_f < new_node.f) {
                        skip = true;
                    }
                }

                if (!skip) {
                    try open_list.add(new_node);
                    try open_cache.put(cache_key, new_node.f);
                }
            }

            try closed_list.append(node);
            try closed_cache.put(node_cache_key, node.f);
        }

        return null;
    }

    pub fn findAllPaths(this: *const @This()) !usize {
        var visited = Visited.init(this.arena.allocator());
        defer visited.deinit();

        _ = try this.aStar(&visited);

        return @intCast(visited.count());
    }

    fn printVisited(this: *const @This(), visited: *Visited) void {
        std.debug.print("===================================================\n", .{});
        for (this.matrix, 0..this.matrix.len) |row, r| {
            for (row, 0..row.len) |cell, c| {
                var char: u8 = if (cell) '.' else '#';
                if (visited.contains(.{ r, c })) {
                    char = 'O';
                }
                std.debug.print("{c}", .{char});
            }

            std.debug.print("\n", .{});
        }
        std.debug.print("===================================================\n", .{});
    }

    fn putPathIntoVisited(path_end: *Node, visited: *Visited) !void {
        var node: ?*Node = path_end;

        while (node) |n| : (node = n.parent) {
            try visited.put(.{ n.pos[0], n.pos[1] }, undefined);
        }
    }

    fn makeNode(this: *const @This(), pos: [2]usize, dir: Dir, g: usize, h: usize, parent: ?*Node) !*Node {
        var node = try this.arena.allocator().create(Node);
        node.pos = .{ pos[0], pos[1] };
        node.dir = dir;
        node.g = g;
        node.h = h;
        node.f = g + h;
        node.parent = parent;

        return node;
    }

    fn getHeuristic(pos: [2]usize, end: [2]usize) usize {
        var score: usize = 0;
        const dr: usize = if (end[0] >= pos[0]) end[0] - pos[0] else pos[0] - end[0];
        const dc: usize = if (end[1] >= pos[1]) end[1] - pos[1] else pos[1] - end[1];

        score += dr + dc;

        return score;
    }

    fn isFree(this: *const @This(), pos: [2]usize) bool {
        return this.matrix[pos[0]][pos[1]];
    }

    fn getForward(pos: [2]usize, dir: Dir) [2]usize {
        return switch (dir) {
            Dir.N => .{ pos[0] - 1, pos[1] },
            Dir.E => .{ pos[0], pos[1] + 1 },
            Dir.S => .{ pos[0] + 1, pos[1] },
            Dir.W => .{ pos[0], pos[1] - 1 },
        };
    }

    fn getLeft(pos: [2]usize, dir: Dir) [2]usize {
        return switch (dir) {
            Dir.N => .{ pos[0], pos[1] - 1 },
            Dir.E => .{ pos[0] - 1, pos[1] },
            Dir.S => .{ pos[0], pos[1] + 1 },
            Dir.W => .{ pos[0] + 1, pos[1] },
        };
    }

    fn getRight(pos: [2]usize, dir: Dir) [2]usize {
        return switch (dir) {
            Dir.N => .{ pos[0], pos[1] + 1 },
            Dir.E => .{ pos[0] + 1, pos[1] },
            Dir.S => .{ pos[0], pos[1] - 1 },
            Dir.W => .{ pos[0] - 1, pos[1] },
        };
    }

    fn turnLeft(dir: Dir) Dir {
        return switch (dir) {
            Dir.N => Dir.W,
            Dir.E => Dir.N,
            Dir.S => Dir.E,
            Dir.W => Dir.S,
        };
    }

    fn turnRight(dir: Dir) Dir {
        return switch (dir) {
            Dir.N => Dir.E,
            Dir.E => Dir.S,
            Dir.S => Dir.W,
            Dir.W => Dir.N,
        };
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
};

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?usize {
    var arena = std.heap.ArenaAllocator.init(this.allocator);
    defer arena.deinit();

    var maze = try Maze.init(&arena, this.input);

    const end = (try maze.aStar(null)).?;
    return end.g;
}

pub fn part2(this: *const @This()) !?usize {
    var arena = std.heap.ArenaAllocator.init(this.allocator);
    defer arena.deinit();

    var maze = try Maze.init(&arena, this.input);
    return try maze.findAllPaths();
}

test "sample input" {
    const allocator = std.testing.allocator;
    const input = "###############\n#.......#....E#\n#.#.###.#.###.#\n#.....#.#...#.#\n#.###.#####.#.#\n#.#.#.......#.#\n#.#.#####.###.#\n#...........#.#\n###.#.#####.#.#\n#...#.....#.#.#\n#.#.#.###.#.#.#\n#.....#...#.#.#\n#.###.#.#.#.#.#\n#S..#.....#...#\n###############\n";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(7036, try problem.part1());
    try std.testing.expectEqual(45, try problem.part2());
}

test "sample input 2" {
    const allocator = std.testing.allocator;
    const input = "#################\n#...#...#...#..E#\n#.#.#.#.#.#.#.#.#\n#.#.#.#...#...#.#\n#.#.#.#.###.#.#.#\n#...#.#.#.....#.#\n#.#.#.#.#.#####.#\n#.#...#.#.#.....#\n#.#.#####.#.###.#\n#.#.#.......#...#\n#.#.###.#####.###\n#.#.#...#.....#.#\n#.#.#.#####.###.#\n#.#.#.........#.#\n#.#.#.#########.#\n#S#.............#\n#################\n";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(11048, try problem.part1());
    try std.testing.expectEqual(64, try problem.part2());
}
