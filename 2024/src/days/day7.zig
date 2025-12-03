const std = @import("std");
const mem = std.mem;

const Equation = struct {
    sum: u64,
    operands: std.ArrayList(u64),
    operand_lengths: std.ArrayList(u64),

    pub fn init(allocator: mem.Allocator, input: []const u8) !Equation {
        var operands = std.ArrayList(u64).init(allocator);
        var operand_lengths = std.ArrayList(u64).init(allocator);
        var part_it = mem.splitSequence(u8, input, ": ");
        const sum = try std.fmt.parseInt(u64, part_it.first(), 10);
        var it = mem.splitScalar(u8, part_it.next().?, ' ');
        while (it.next()) |op| {
            try operands.append(try std.fmt.parseInt(u64, op, 10));
            try operand_lengths.append(@intCast(op.len));
        }

        return Equation{
            .sum = sum,
            .operands = operands,
            .operand_lengths = operand_lengths,
        };
    }

    pub fn free(this: *@This()) void {
        this.operands.deinit();
        this.operand_lengths.deinit();
    }

    pub fn isTrue(this: *const @This(), concat: bool) bool {
        if (concat) {
            return this.hasSolutionWithConcat(1, this.operands.items[0]);
        }

        return this.hasSolution(1, this.operands.items[0]);
    }

    fn hasSolution(this: *const @This(), current_index: usize, current_sum: u64) bool {
        if (current_index == this.operands.items.len) {
            return current_sum == this.sum;
        }

        if (this.hasSolution(current_index + 1, current_sum + this.operands.items[current_index])) {
            return true;
        }

        return this.hasSolution(current_index + 1, current_sum * this.operands.items[current_index]);
    }

    fn hasSolutionWithConcat(this: *const @This(), current_index: usize, current_sum: u64) bool {
        if (current_index == this.operands.items.len) {
            return current_sum == this.sum;
        }

        if (this.hasSolutionWithConcat(current_index + 1, current_sum + this.operands.items[current_index])) {
            return true;
        }

        if (this.hasSolutionWithConcat(current_index + 1, current_sum * this.operands.items[current_index])) {
            return true;
        }

        return this.hasSolutionWithConcat(current_index + 1, current_sum * std.math.pow(u64, 10, this.operand_lengths.items[current_index]) + this.operands.items[current_index]);
    }
};

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?u64 {
    var list = std.ArrayList(Equation).init(this.allocator);
    defer list.deinit();

    try this.parseEquations(&list);

    var sum: u64 = 0;
    for (list.items) |*eq| {
        defer eq.free();

        if (eq.isTrue(false)) {
            sum += eq.sum;
        }
    }

    return sum;
}

pub fn part2(this: *const @This()) !?u64 {
    var list = std.ArrayList(Equation).init(this.allocator);
    defer list.deinit();

    try this.parseEquations(&list);

    var sum: u64 = 0;
    for (list.items) |*eq| {
        defer eq.free();
        if (eq.isTrue(true)) {
            sum += eq.sum;
        }
    }

    return sum;
}

fn parseEquations(this: *const @This(), list: *std.ArrayList(Equation)) !void {
    var it = mem.splitSequence(u8, this.input, "\n");
    while (it.next()) |line| {
        if (line.len < 1) continue;
        try list.append(try Equation.init(this.allocator, line));
    }
}

test "sample input" {
    const allocator = std.testing.allocator;
    const input = "190: 10 19\n3267: 81 40 27\n83: 17 5\n156: 15 6\n7290: 6 8 6 15\n161011: 16 10 13\n192: 17 8 14\n21037: 9 7 18 13\n292: 11 6 16 20\n";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(3749, try problem.part1());
    try std.testing.expectEqual(11387, try problem.part2());
}
