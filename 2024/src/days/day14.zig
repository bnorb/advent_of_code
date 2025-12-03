const std = @import("std");
const mem = std.mem;

const Robot = struct {
    start: [2]i16,
    pos: [2]i16,
    velocity: [2]i16,
    height: i16,
    width: i16,

    pub fn init(line: []const u8, height: i16, width: i16) !Robot {
        var it = mem.splitScalar(u8, line, ' ');
        const start = try parseVector(it.next().?);
        return Robot{
            .start = start,
            .pos = start,
            .velocity = try parseVector(it.next().?),
            .height = height,
            .width = width,
        };
    }

    pub fn simulate(this: *@This(), seconds: u32) void {
        for (0..seconds) |_| {
            this.move();
        }
    }

    pub fn move(this: *@This()) void {
        var next: [2]i16 = .{ this.pos[0] + this.velocity[0], this.pos[1] + this.velocity[1] };
        if (next[0] < 0) {
            next[0] = this.width + next[0];
        } else if (next[0] >= this.width) {
            next[0] = next[0] - this.width;
        }

        if (next[1] < 0) {
            next[1] = this.height + next[1];
        } else if (next[1] >= this.height) {
            next[1] = next[1] - this.height;
        }

        this.pos = next;
    }

    fn parseVector(str: []const u8) ![2]i16 {
        var it = mem.splitScalar(u8, str, '=');
        _ = it.next();

        var it2 = mem.splitScalar(u8, it.next().?, ',');
        return .{ try std.fmt.parseInt(i16, it2.next().?, 10), try std.fmt.parseInt(i16, it2.next().?, 10) };
    }
};

input: []const u8,
allocator: mem.Allocator,
height: i16 = 103,
width: i16 = 101,

pub fn part1(this: *const @This()) !?u64 {
    var it = mem.splitSequence(u8, this.input, "\n");
    var ends = std.ArrayList([2]i16).init(this.allocator);
    defer ends.deinit();

    while (it.next()) |line| {
        if (line.len < 1) continue;

        var robot = try Robot.init(line, this.height, this.width);
        robot.simulate(100);
        try ends.append(robot.pos);
    }

    const quadrants = this.getQuadrants();

    var quad_counts: [4]u64 = .{ 0, 0, 0, 0 };
    for (ends.items) |end| {
        for (quadrants, 0..4) |quad, i| {
            if (end[0] >= quad[0] and end[0] <= quad[2] and end[1] >= quad[1] and end[1] <= quad[3]) {
                quad_counts[i] += 1;
                break;
            }
        }
    }

    var prod: u64 = 1;
    for (quad_counts) |c| {
        prod *= c;
    }

    return prod;
}

pub fn part2(this: *const @This()) !?i64 { // print to log file, look through
    var it = mem.splitSequence(u8, this.input, "\n");
    var robots: []Robot = try this.allocator.alloc(Robot, 500);
    defer this.allocator.free(robots);

    var robot_i: usize = 0;
    while (it.next()) |line| : (robot_i += 1) {
        if (line.len < 1) continue;

        robots[robot_i] = try Robot.init(line, this.height, this.width);
    }

    const quadrants = this.getQuadrants();
    var map: [][]u8 = try this.allocator.alloc([]u8, @intCast(this.height));
    defer this.freeMap(map);

    for (0..@intCast(this.height)) |i| {
        map[i] = try this.allocator.alloc(u8, @intCast(this.width));
    }

    const expected_range: [2]u16 = .{ 80, 170 };

    for (0..20000) |second| {
        var quad_counts: [4]u16 = .{ 0, 0, 0, 0 };
        for (robots) |robot| {
            for (quadrants, 0..4) |quad, i| {
                if (robot.pos[0] >= quad[0] and robot.pos[0] <= quad[2] and robot.pos[1] >= quad[1] and robot.pos[1] <= quad[3]) {
                    quad_counts[i] += 1;
                    break;
                }
            }
        }

        var signal = false;
        for (quad_counts) |c| {
            if (c < expected_range[0] or c > expected_range[1]) {
                signal = true;
                break;
            }
        }

        if (signal) {
            std.debug.print("state at {d} second\n\n", .{second});
            std.debug.print("{any}\n\n", .{quad_counts});
            this.clearMap(map);
            fillMap(map, robots);
            printMap(map);
        }

        for (robots) |*robot| {
            robot.move();
        }
    }

    this.clearMap(map);
    fillMap(map, robots);
    printMap(map);

    return null;
}

fn getQuadrants(this: @This()) [4][4]i16 {
    const half_h = @divTrunc((this.height - 1), 2);
    const half_w = @divTrunc((this.width - 1), 2);

    return .{ // minW, minH, maxW, maxH inclusive
        .{ 0, 0, half_w - 1, half_h - 1 },
        .{ 0, half_h + 1, half_w - 1, this.height - 1 },
        .{ half_w + 1, 0, this.width - 1, half_h - 1 },
        .{ half_w + 1, half_h + 1, this.width - 1, this.height - 1 },
    };
}

fn fillMap(map: [][]u8, robots: []Robot) void {
    for (robots) |robot| {
        const row: usize = @intCast(robot.pos[1]);
        const col: usize = @intCast(robot.pos[0]);

        map[row][col] = '#';
    }
}

fn clearMap(this: *const @This(), map: [][]u8) void {
    for (0..@intCast(this.height)) |row| {
        for (0..@intCast(this.width)) |col| {
            map[row][col] = '.';
        }
    }
}

fn printMap(map: [][]u8) void {
    std.debug.print("===================================================\n", .{});
    for (map) |row| {
        std.debug.print("{s}\n", .{row});
    }
    std.debug.print("===================================================\n", .{});
}

fn freeMap(this: *const @This(), map: [][]u8) void {
    for (map) |row| {
        this.allocator.free(row);
    }

    this.allocator.free(map);
}

test "sample input" {
    const allocator = std.testing.allocator;
    const input = "p=0,4 v=3,-3\np=6,3 v=-1,-3\np=10,3 v=-1,2\np=2,0 v=2,-1\np=0,0 v=1,3\np=3,0 v=-2,-2\np=7,6 v=-1,-3\np=3,0 v=-1,-2\np=9,3 v=2,3\np=7,3 v=-1,2\np=2,4 v=2,-3\np=9,5 v=-3,-3\n";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
        .height = 7,
        .width = 11,
    };

    try std.testing.expectEqual(12, try problem.part1());
    try std.testing.expectEqual(null, try problem.part2());
}
