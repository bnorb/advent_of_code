const std = @import("std");
const mem = std.mem;

const DIRS: [4][2]isize = .{
    .{ -1, 0 },
    .{ 1, 0 },
    .{ 0, -1 },
    .{ 0, 1 },
};

const Queue = std.DoublyLinkedList([2]usize);
const Set = std.AutoHashMap([2]usize, void);
const SideSet = std.AutoHashMap(struct { usize, usize, bool }, void);

const Garden = struct {
    allocator: mem.Allocator,
    height: usize,
    width: usize,
    matrix: [][]u8,
    visited: Set,

    pub fn init(allocator: mem.Allocator, input: []const u8) !Garden {
        const dimensions = getDimensions(input);
        var matrix: [][]u8 = try allocator.alloc([]u8, dimensions[0]);

        var it = mem.splitSequence(u8, input, "\n");

        var index: usize = 0;
        while (it.next()) |line| : (index += 1) {
            if (line.len < 1) {
                continue;
            }

            matrix[index] = try allocator.alloc(u8, dimensions[1]);
            @memcpy(matrix[index], line);
        }

        return Garden{
            .allocator = allocator,
            .height = dimensions[0],
            .width = dimensions[1],
            .matrix = matrix,
            .visited = Set.init(allocator),
        };
    }

    pub fn free(this: *@This()) void {
        for (this.matrix) |row| {
            this.allocator.free(row);
        }

        this.allocator.free(this.matrix);
        this.visited.deinit();
    }

    pub fn printMap(this: *const @This()) void {
        std.debug.print("\n==================\n", .{});
        for (this.matrix) |row| {
            std.debug.print("{s}\n", .{row});
        }
        std.debug.print("==================\n", .{});
    }

    pub fn calcCost(this: *@This(), sides: bool) !u32 {
        var region = Set.init(this.allocator);
        defer region.deinit();

        var sum: u32 = 0;
        for (0..this.height) |r| {
            for (0..this.width) |c| {
                if (this.visited.contains(.{ r, c })) {
                    continue;
                }

                try this.findRegion(.{ r, c }, &region);

                if (sides) {
                    sum += try this.calcRegionCostSides(&region);
                } else {
                    sum += this.calcRegionCost(&region);
                }

                var it = region.keyIterator();
                while (it.next()) |key| {
                    try this.visited.put(.{ key[0], key[1] }, undefined);
                    region.removeByPtr(key);
                }
            }
        }

        return sum;
    }

    fn calcRegionCostSides(this: *const @This(), region: *Set) !u32 {
        var vertical_sides = SideSet.init(this.allocator);
        defer vertical_sides.deinit();

        var horizontal_sides = SideSet.init(this.allocator);
        defer horizontal_sides.deinit();

        try this.fillSides(region, &vertical_sides, &horizontal_sides);
        const bounds: [4]usize = getBounds(region); // minH, minW, maxH, maxW

        var all_sides: u32 = 0;
        all_sides += countSides(bounds, &horizontal_sides, false);
        all_sides += countSides(bounds, &vertical_sides, true);

        return all_sides * region.count();
    }

    fn countSides(bounds: [4]usize, side_set: *SideSet, vertical: bool) u32 {
        var outer = .{ bounds[0], bounds[2] };
        var inner = .{ bounds[1], bounds[3] };
        if (vertical) {
            outer = .{ bounds[1], bounds[3] };
            inner = .{ bounds[0], bounds[2] };
        }

        var all_sides: u32 = 0;
        for (outer[0]..outer[1] + 1) |o| {
            var sides: u32 = 0;
            var side_1 = false;
            var side_2 = false;

            for (inner[0]..inner[1] + 1) |i| {
                var r = o;
                var c = i;
                if (vertical) {
                    r = i;
                    c = o;
                }

                if (side_set.contains(.{ r, c, false })) {
                    side_1 = true;
                } else {
                    if (side_1) {
                        sides += 1;
                    }

                    side_1 = false;
                }

                if (side_set.contains(.{ r, c, true })) {
                    side_2 = true;
                } else {
                    if (side_2) {
                        sides += 1;
                    }

                    side_2 = false;
                }
            }

            if (side_1) sides += 1;
            if (side_2) sides += 1;

            all_sides += sides;
        }

        return all_sides;
    }

    fn fillSides(this: *const @This(), region: *Set, vertical_sides: *SideSet, horizontal_sides: *SideSet) !void {
        var it = region.keyIterator();
        while (it.next()) |key| {
            const neighbors = getNeighbors(.{ key[0], key[1] });
            for (neighbors) |neighbor| {
                if (this.toValid(neighbor)) |next| {
                    if (!region.contains(next)) {
                        if (key[0] == next[0]) {
                            try vertical_sides.put(.{ key[0], key[1], key[1] < next[1] }, undefined);
                        } else {
                            try horizontal_sides.put(.{ key[0], key[1], key[0] < next[0] }, undefined);
                        }
                    }
                } else {
                    const curr_row: isize = @intCast(key[0]);
                    const curr_col: isize = @intCast(key[1]);

                    if (curr_row == neighbor[0]) {
                        try vertical_sides.put(.{ key[0], key[1], curr_col < neighbor[1] }, undefined);
                    } else {
                        try horizontal_sides.put(.{ key[0], key[1], curr_row < neighbor[0] }, undefined);
                    }
                }
            }
        }
    }

    fn getBounds(region: *Set) [4]usize {
        var bounds: [4]usize = .{ std.math.maxInt(usize), std.math.maxInt(usize), 0, 0 };
        var it = region.keyIterator();
        while (it.next()) |key| {
            if (key[0] < bounds[0]) {
                bounds[0] = key[0];
            }

            if (key[0] > bounds[2]) {
                bounds[2] = key[0];
            }

            if (key[1] < bounds[1]) {
                bounds[1] = key[1];
            }

            if (key[1] > bounds[3]) {
                bounds[3] = key[1];
            }
        }

        return bounds;
    }

    fn calcRegionCost(this: *const @This(), region: *Set) u32 {
        var it = region.keyIterator();
        var perimeter: u32 = 0;
        while (it.next()) |key| {
            const neighbors = getNeighbors(.{ key[0], key[1] });
            for (neighbors) |neighbor| {
                if (this.toValid(neighbor)) |next| {
                    if (!region.contains(next)) {
                        perimeter += 1;
                    }
                } else {
                    perimeter += 1;
                }
            }
        }

        return perimeter * region.count();
    }

    fn findRegion(this: *@This(), start: [2]usize, region: *Set) !void {
        var queue = Queue{};
        errdefer this.freeQueue(&queue);

        var startNode = try this.allocator.create(Queue.Node);
        startNode.data = .{ start[0], start[1] };
        queue.append(startNode);
        try region.put(.{ start[0], start[1] }, undefined);

        const plant = this.matrix[start[0]][start[1]];
        while (queue.popFirst()) |curr| {
            const neighbors = getNeighbors(curr.data);
            this.allocator.destroy(curr);

            for (neighbors) |neighbor| {
                if (this.toValid(neighbor)) |next| {
                    if (region.contains(next)) {
                        continue;
                    }

                    if (this.matrix[next[0]][next[1]] != plant) {
                        continue;
                    }

                    try region.put(.{ next[0], next[1] }, undefined);

                    var node = try this.allocator.create(Queue.Node);
                    node.data = .{ next[0], next[1] };
                    queue.append(node);
                }
            }
        }
    }

    fn toValid(this: *const @This(), cell: [2]isize) ?[2]usize {
        if (cell[0] < 0 or cell[1] < 0) {
            return null;
        }

        const valid: [2]usize = .{ @intCast(cell[0]), @intCast(cell[1]) };
        if (valid[0] >= this.height or valid[1] >= this.width) {
            return null;
        }

        return valid;
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

    fn freeQueue(this: *@This(), queue: *Queue) void {
        while (queue.pop()) |node| {
            this.allocator.destroy(node);
        }
    }

    fn getDimensions(input: []const u8) [2]usize {
        var it = mem.splitSequence(u8, input, "\n");

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
};

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?u32 {
    var garden = try Garden.init(this.allocator, this.input);
    defer garden.free();

    return try garden.calcCost(false);
}

pub fn part2(this: *const @This()) !?i64 {
    var garden = try Garden.init(this.allocator, this.input);
    defer garden.free();

    return try garden.calcCost(true);
}

test "sample input" {
    const allocator = std.testing.allocator;
    const input = "RRRRIICCFF\nRRRRIICCCF\nVVRRRCCFFF\nVVRCCCJFFF\nVVVVCJJCFE\nVVIVCCJJEE\nVVIIICJJEE\nMIIIIIJJEE\nMIIISIJEEE\nMMMISSJEEE\n";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(1930, try problem.part1());
    try std.testing.expectEqual(1206, try problem.part2());
}
