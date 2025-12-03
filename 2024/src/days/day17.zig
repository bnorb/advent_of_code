const std = @import("std");
const mem = std.mem;

const Computer = struct {
    allocator: mem.Allocator,
    a: usize,
    b: usize,
    c: usize,
    prog: []usize,
    output: std.ArrayList(u8),
    inst: usize = 0,

    pub fn init(allocator: mem.Allocator, input: []const u8) !Computer {
        var it = mem.splitSequence(u8, input, "\n");
        const output = std.ArrayList(u8).init(allocator);

        const a = try parseRegister(it.next().?);
        const b = try parseRegister(it.next().?);
        const c = try parseRegister(it.next().?);
        _ = it.next();

        return Computer{
            .allocator = allocator,
            .a = a,
            .b = b,
            .c = c,
            .prog = try parseProgram(allocator, it.next().?),
            .output = output,
        };
    }

    pub fn runProgram(this: *@This()) !void {
        while (this.inst < this.prog.len) {
            switch (this.prog[this.inst]) {
                0 => this.adv(this.prog[this.inst + 1]),
                1 => this.bxl(this.prog[this.inst + 1]),
                2 => this.bst(this.prog[this.inst + 1]),
                3 => this.jnz(this.prog[this.inst + 1]),
                4 => this.bxc(),
                5 => try this.out(this.prog[this.inst + 1]),
                6 => this.bdv(this.prog[this.inst + 1]),
                7 => this.cdv(this.prog[this.inst + 1]),
                else => unreachable,
            }
        }
    }

    // Register A: 28066687
    // Register B: 0
    // Register C: 0

    // Program: 2,4,1,1,7,5,4,6,0,3,1,4,5,5,3,0

    // bst A - Set B to [A % 8]     -> Set B between 0..7
    // bxl 1 - Set B to [B XOR 1]
    // cdv B - Set C to [A / 2^B]
    // bxc   - Set B to [B XOR C]   -> only last 3 bits depend on both, rest is just C
    // adv 3 - Divide A by 8
    // bxl 4 - Set B to [B XOR 4]   -> only bit in pos 3 changes
    // out B - print B % 8
    // jnz 0 - terminate if A is 0, otherwise start again

    // We know that A must be 0 at the end, cause program terminates.
    // At each cycle, B and C ONLY depend on the value on A.
    // At each cycle, A is just divided by 8. Which means at the start of the last cycle, A is between 0..7 (0 not possible tho).
    // That means, we only have to validate 7 possible answers for the last A value, then 7 for the next, as the previous value is between A*8..(A+1)*8.
    pub fn findA(this: *@This(), acc: usize, digit: usize) !?usize {
        for (acc * 8..(acc + 1) * 8) |a| {
            this.reset(a);
            try this.runProgram();
            if (this.outputEqualsProgram(digit)) {
                if (digit == 0) {
                    return a;
                }

                if (try this.findA(a, digit - 1)) |found_a| {
                    return found_a;
                }
            }
        }

        return null;
    }

    fn outputEqualsProgram(this: *const @This(), from_digit: usize) bool {
        for (this.output.items, this.prog[from_digit..this.prog.len]) |o, p| {
            const p8: u8 = @intCast(p);
            if (o != p8) return false;
        }

        return true;
    }

    fn reset(this: *@This(), a: usize) void {
        this.a = a;
        this.b = 0;
        this.c = 0;
        this.inst = 0;
        this.output.clearAndFree();
    }

    fn combo(this: *@This(), operand: usize) usize {
        return switch (operand) {
            0, 1, 2, 3 => operand,
            4 => this.a,
            5 => this.b,
            6 => this.c,
            else => unreachable,
        };
    }

    fn adv(this: *@This(), operand: usize) void {
        this.a = @divTrunc(this.a, std.math.pow(usize, 2, this.combo(operand)));
        this.inst += 2;
    }

    fn bxl(this: *@This(), operand: usize) void {
        this.b = this.b ^ operand;
        this.inst += 2;
    }

    fn bst(this: *@This(), operand: usize) void {
        this.b = this.combo(operand) % 8;
        this.inst += 2;
    }

    fn jnz(this: *@This(), operand: usize) void {
        if (this.a == 0) {
            this.inst += 2;
            return;
        }

        this.inst = operand;
    }

    fn bxc(this: *@This()) void {
        this.b = this.b ^ this.c;
        this.inst += 2;
    }

    fn out(this: *@This(), operand: usize) !void {
        const res = this.combo(operand) % 8;
        try this.output.append(@intCast(res));
        this.inst += 2;
    }

    fn bdv(this: *@This(), operand: usize) void {
        this.b = @divTrunc(this.a, std.math.pow(usize, 2, this.combo(operand)));
        this.inst += 2;
    }

    fn cdv(this: *@This(), operand: usize) void {
        this.c = @divTrunc(this.a, std.math.pow(usize, 2, this.combo(operand)));
        this.inst += 2;
    }

    pub fn deinit(this: *@This()) void {
        this.allocator.free(this.prog);
        this.output.deinit();
    }

    fn parseRegister(line: []const u8) !usize {
        const colon = mem.indexOf(u8, line, ":").?;
        return try std.fmt.parseInt(usize, line[colon + 2 .. line.len], 10);
    }

    fn parseProgram(allocator: mem.Allocator, line: []const u8) ![]usize {
        const colon = mem.indexOf(u8, line, ":").?;
        var it = mem.splitScalar(u8, line[colon + 2 .. line.len], ',');
        var len: usize = 0;
        while (it.next()) |_| {
            len += 1;
        }

        it.reset();

        var prog = try allocator.alloc(usize, len);
        var i: usize = 0;
        while (it.next()) |part| : (i += 1) {
            prog[i] = try std.fmt.parseInt(usize, part, 10);
        }

        return prog;
    }
};

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?[]u8 {
    var computer = try Computer.init(this.allocator, this.input);
    defer computer.deinit();

    try computer.runProgram();
    const len = 2 * computer.output.items.len - 1;
    var out: []u8 = try this.allocator.alloc(u8, len);
    var i: usize = 0;
    for (computer.output.items) |val| {
        out[i] = val + 48;
        if (i + 1 < len) {
            out[i + 1] = ',';
        }

        i += 2;
    }

    return out;
}

pub fn part2(this: *const @This()) !?u64 {
    var computer = try Computer.init(this.allocator, this.input);
    defer computer.deinit();

    return (try computer.findA(0, 15)).?;
}

test "sample input part 1" {
    const allocator = std.testing.allocator;
    const input = "Register A: 729\nRegister B: 0\nRegister C: 0\n\nProgram: 0,1,5,4,3,0\n";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    const res1 = (try problem.part1()).?;
    defer allocator.free(res1);

    try std.testing.expectEqualStrings("4,6,3,5,6,3,5,2,1,0", res1);
    try std.testing.expectEqual(null, try problem.part2());
}
