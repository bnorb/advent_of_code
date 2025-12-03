const std = @import("std");
const mem = std.mem;

const ClawMachine = struct {
    v_a: [2]i64,
    v_b: [2]i64,
    p: [2]i64,

    pub fn init(input: []const u8, offset: i64) !ClawMachine {
        var it = mem.splitSequence(u8, input, "\n");
        const v_a = try parseLine(it.next().?, '+');
        const v_b = try parseLine(it.next().?, '+');

        var p = try parseLine(it.next().?, '=');
        p[0] += offset;
        p[1] += offset;

        return ClawMachine{
            .v_a = v_a,
            .v_b = v_b,
            .p = p,
        };
    }

    pub fn minCost(this: *const @This()) ?i64 {
        const c_b = std.math.divExact(i64, (this.v_a[1] * this.p[0]) - (this.v_a[0] * this.p[1]), (this.v_a[1] * this.v_b[0]) - (this.v_a[0] * this.v_b[1])) catch {
            return null;
        };

        const c_a = std.math.divExact(i64, this.p[0] - (c_b * this.v_b[0]), this.v_a[0]) catch {
            return null;
        };

        return c_a * 3 + c_b;
    }

    fn parseLine(line: []const u8, delimiter: u8) ![2]i64 {
        var it1 = mem.splitSequence(u8, line, ": ");
        _ = it1.next();
        var it2 = mem.splitSequence(u8, it1.next().?, ", ");

        return .{ try parseNum(it2.next().?, delimiter), try parseNum(it2.next().?, delimiter) };
    }

    fn parseNum(str: []const u8, delimiter: u8) !i64 {
        var it = mem.splitScalar(u8, str, delimiter);
        _ = it.next();

        return try std.fmt.parseInt(i64, it.next().?, 10);
    }
};

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?i64 {
    var sum: i64 = 0;

    var it = mem.splitSequence(u8, this.input, "\n\n");
    while (it.next()) |cm| {
        const claw_machine = try ClawMachine.init(cm, 0);
        if (claw_machine.minCost()) |cost| {
            sum += cost;
        }
    }

    return sum;
}

pub fn part2(this: *const @This()) !?i64 {
    var sum: i64 = 0;

    var it = mem.splitSequence(u8, this.input, "\n\n");
    while (it.next()) |cm| {
        const claw_machine = try ClawMachine.init(cm, 10000000000000);
        if (claw_machine.minCost()) |cost| {
            sum += cost;
        }
    }

    return sum;
}

test "sample input" {
    const allocator = std.testing.allocator;
    const input = "Button A: X+94, Y+34\nButton B: X+22, Y+67\nPrize: X=8400, Y=5400\n\nButton A: X+26, Y+66\nButton B: X+67, Y+21\nPrize: X=12748, Y=12176\n\nButton A: X+17, Y+86\nButton B: X+84, Y+37\nPrize: X=7870, Y=6450\n\nButton A: X+69, Y+23\nButton B: X+27, Y+71\nPrize: X=18641, Y=10279\n";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(480, try problem.part1());
    try std.testing.expectEqual(875318608908, try problem.part2());
}
