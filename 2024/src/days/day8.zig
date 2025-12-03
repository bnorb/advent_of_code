const std = @import("std");
const mem = std.mem;

const Coords = [2]isize;
const AntennaMap = std.AutoHashMap(u8, std.ArrayList(Coords));
const AntiNodeSet = std.AutoHashMap(Coords, void);

const Map = struct {
    width: isize,
    height: isize,
    antennas: AntennaMap,
    antinodes: AntiNodeSet,

    pub fn init(allocator: mem.Allocator, input: []const u8) !Map {
        var antennas = AntennaMap.init(allocator);
        var it = mem.splitSequence(u8, input, "\n");

        var height: isize = 0;
        var width: isize = 0;
        while (it.next()) |line| {
            if (line.len < 1) continue;

            if (width == 0) {
                width = @intCast(line.len);
            }

            for (line, 0..) |c, col| {
                if (c == '.') continue;

                var entry = try antennas.getOrPut(c);
                if (!entry.found_existing) {
                    entry.value_ptr.* = std.ArrayList(Coords).init(allocator);
                }

                try entry.value_ptr.append(.{ height, @intCast(col) });
            }

            height += 1;
        }

        return Map{
            .width = width,
            .height = height,
            .antennas = antennas,
            .antinodes = AntiNodeSet.init(allocator),
        };
    }

    pub fn free(this: *@This()) void {
        defer this.antennas.deinit();
        defer this.antinodes.deinit();

        var it = this.antennas.valueIterator();
        while (it.next()) |list| {
            defer list.deinit();
        }
    }

    pub fn findAntinodes(this: *@This()) !AntiNodeSet.Size {
        var it = this.antennas.valueIterator();
        while (it.next()) |list| {
            if (list.items.len < 2) continue;

            for (list.items[0 .. list.items.len - 1], 0..list.items.len - 1) |antenna_1, index| {
                for (list.items[index + 1 ..]) |antenna_2| {
                    const antinode_1 = .{ 2 * antenna_1[0] - antenna_2[0], 2 * antenna_1[1] - antenna_2[1] };
                    const antinode_2 = .{ 2 * antenna_2[0] - antenna_1[0], 2 * antenna_2[1] - antenna_1[1] };

                    if (this.isInBounds(antinode_1)) try this.antinodes.put(antinode_1, undefined);
                    if (this.isInBounds(antinode_2)) try this.antinodes.put(antinode_2, undefined);
                }
            }
        }

        return this.antinodes.count();
    }

    pub fn findAntinodesWithHarmonics(this: *@This()) !AntiNodeSet.Size {
        const upper_limit: usize = @intCast(@max(this.width, this.height));
        var it = this.antennas.valueIterator();
        while (it.next()) |list| {
            if (list.items.len < 2) continue;

            for (list.items[0 .. list.items.len - 1], 0..list.items.len - 1) |antenna_1, index| {
                for (list.items[index + 1 ..]) |antenna_2| {
                    const v: Coords = .{ antenna_2[0] - antenna_1[0], antenna_2[1] - antenna_1[1] };

                    for (1..upper_limit) |i| {
                        const j: isize = @intCast(i);
                        const antinode: Coords = .{ antenna_1[0] + j * v[0], antenna_1[1] + j * v[1] };
                        if (this.isInBounds(antinode)) try this.antinodes.put(antinode, undefined);
                    }

                    for (1..upper_limit) |i| {
                        const j: isize = @intCast(i);
                        const antinode: Coords = .{ antenna_2[0] - j * v[0], antenna_2[1] - j * v[1] };
                        if (this.isInBounds(antinode)) try this.antinodes.put(antinode, undefined);
                    }
                }
            }
        }

        return this.antinodes.count();
    }

    fn isInBounds(this: *const @This(), node: Coords) bool {
        return node[0] >= 0 and node[0] < this.height and node[1] >= 0 and node[1] < this.width;
    }
};

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?AntiNodeSet.Size {
    var map = try Map.init(this.allocator, this.input);
    defer map.free();

    return try map.findAntinodes();
}

pub fn part2(this: *const @This()) !?i64 {
    var map = try Map.init(this.allocator, this.input);
    defer map.free();

    return try map.findAntinodesWithHarmonics();
}

test "sample input" {
    const allocator = std.testing.allocator;
    const input = "............\n........0...\n.....0......\n.......0....\n....0.......\n......A.....\n............\n............\n........A...\n.........A..\n............\n............";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(14, try problem.part1());
    try std.testing.expectEqual(34, try problem.part2());
}
