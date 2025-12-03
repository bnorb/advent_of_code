const std = @import("std");
const mem = std.mem;

const Mul = struct {
    num1: std.ArrayList(u8),
    num2: std.ArrayList(u8),
    first_num_complete: bool = false,
    num_remaining: u8 = 3,
    valid_count: u8 = 0,

    pub fn init(allocator: mem.Allocator) Mul {
        return Mul{
            .num1 = std.ArrayList(u8).init(allocator),
            .num2 = std.ArrayList(u8).init(allocator),
        };
    }

    pub fn free(this: *@This()) void {
        this.num1.deinit();
        this.num2.deinit();
    }

    pub fn parse(this: *@This(), prev_char: u8, curr_char: u8) !?u64 {
        var val: ?u64 = null;

        if (this.isValid(prev_char, curr_char)) {
            if (curr_char == 'm') {
                try this.reset();
            }

            this.valid_count += 1;

            if (curr_char == ')') {
                const expected_count = this.num1.items.len + this.num2.items.len + 6;

                if (this.valid_count == expected_count) {
                    val = try std.fmt.parseInt(u64, this.num1.items, 10) * try std.fmt.parseInt(u64, this.num2.items, 10);
                }

                try this.reset();
            } else if (curr_char == ',') {
                this.first_num_complete = true;
                this.num_remaining = 3;
            } else if (isNumber(curr_char)) {
                this.num_remaining -= 1;
                if (this.first_num_complete) {
                    try this.num2.append(curr_char);
                } else {
                    try this.num1.append(curr_char);
                }
            }
        } else {
            try this.reset();
        }

        return val;
    }

    fn reset(this: *@This()) !void {
        try this.num1.resize(0);
        try this.num2.resize(0);
        this.first_num_complete = false;
        this.num_remaining = 3;
        this.valid_count = 0;
    }

    fn isValid(this: *@This(), prev_char: u8, curr_char: u8) bool {
        if (curr_char == 'm') return true;

        if (prev_char == '(' or prev_char == ',') {
            return isNumber(curr_char);
        }

        if (isNumber(prev_char)) {
            if (isNumber(curr_char)) {
                return this.num_remaining > 0;
            }

            if (this.first_num_complete) {
                return curr_char == ')';
            }

            return curr_char == ',';
        }

        return switch (prev_char) {
            'm' => curr_char == 'u',
            'u' => curr_char == 'l',
            'l' => curr_char == '(',
            else => curr_char == 'm',
        };
    }
};

const Do = struct {
    valid_count: u8 = 0,

    pub fn parse(this: *@This(), prev_char: u8, curr_char: u8) bool {
        var val: bool = false;

        if (Do.isValid(prev_char, curr_char)) {
            if (curr_char == 'd') {
                this.reset();
            }

            this.valid_count += 1;

            if (curr_char == ')') {
                if (this.valid_count == 4) {
                    val = true;
                }

                this.reset();
            }
        } else {
            this.reset();
        }

        return val;
    }

    fn reset(this: *@This()) void {
        this.valid_count = 0;
    }

    fn isValid(prev_char: u8, curr_char: u8) bool {
        if (curr_char == 'd') return true;

        return switch (prev_char) {
            'd' => curr_char == 'o',
            'o' => curr_char == '(',
            '(' => curr_char == ')',
            else => curr_char == 'd',
        };
    }
};

const Dont = struct {
    valid_count: u8 = 0,

    pub fn parse(this: *@This(), prev_char: u8, curr_char: u8) bool {
        var val: bool = false;

        if (Dont.isValid(prev_char, curr_char)) {
            if (curr_char == 'd') {
                this.reset();
            }

            this.valid_count += 1;

            if (curr_char == ')') {
                if (this.valid_count == 7) {
                    val = true;
                }

                this.reset();
            }
        } else {
            this.reset();
        }

        return val;
    }

    fn reset(this: *@This()) void {
        this.valid_count = 0;
    }

    fn isValid(prev_char: u8, curr_char: u8) bool {
        if (curr_char == 'd') return true;

        return switch (prev_char) {
            'd' => curr_char == 'o',
            'o' => curr_char == 'n',
            'n' => curr_char == '\'',
            '\'' => curr_char == 't',
            't' => curr_char == '(',
            '(' => curr_char == ')',
            else => curr_char == 'd',
        };
    }
};

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?u64 {
    var sum: u64 = 0;
    var mul = Mul.init(this.allocator);
    defer mul.free();

    for (1..this.input.len) |index| {
        const prev_char = this.input[index - 1];
        const curr_char = this.input[index];

        if (try mul.parse(prev_char, curr_char)) |val| {
            sum += val;
        }
    }

    return sum;
}

pub fn part2(this: *const @This()) !?u64 {
    var sum: u64 = 0;
    var mul = Mul.init(this.allocator);
    var do = Do{};
    var dont = Dont{};
    defer mul.free();

    var enabled = true;

    for (1..this.input.len) |index| {
        const prev_char = this.input[index - 1];
        const curr_char = this.input[index];

        if (do.parse(prev_char, curr_char)) {
            enabled = true;
        }

        if (dont.parse(prev_char, curr_char)) {
            enabled = false;
        }

        if (try mul.parse(prev_char, curr_char)) |val| {
            if (enabled) {
                sum += val;
            }
        }
    }

    return sum;
}

fn isValid(prev_char: u8, curr_char: u8, first_num_complete: bool, num_remaining: u8) bool {
    if (curr_char == 'm') return true;

    if (prev_char == '(' or prev_char == ',') {
        return isNumber(curr_char);
    }

    if (isNumber(prev_char)) {
        if (isNumber(curr_char)) {
            return num_remaining > 0;
        }

        if (first_num_complete) {
            return curr_char == ')';
        }

        return curr_char == ',';
    }

    return switch (prev_char) {
        'm' => curr_char == 'u',
        'u' => curr_char == 'l',
        'l' => curr_char == '(',
        else => curr_char == 'm',
    };
}

fn isNumber(char: u8) bool {
    return char >= 48 and char <= 57;
}

test isNumber {
    try std.testing.expect(isNumber('0'));
    try std.testing.expect(isNumber('1'));
    try std.testing.expect(isNumber('2'));
    try std.testing.expect(isNumber('3'));
    try std.testing.expect(isNumber('4'));
    try std.testing.expect(isNumber('5'));
    try std.testing.expect(isNumber('6'));
    try std.testing.expect(isNumber('7'));
    try std.testing.expect(isNumber('8'));
    try std.testing.expect(isNumber('9'));
    try std.testing.expect(!isNumber(':'));
    try std.testing.expect(!isNumber('/'));
}

test "part1 should work on sample" {
    const allocator = std.testing.allocator;
    const input = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(161, try problem.part1());
}

test "part2 should work on sample" {
    const allocator = std.testing.allocator;
    const input = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(48, try problem.part2());
}

test "part1 should work on other sample" {
    const allocator = std.testing.allocator;
    const input = "xmul(1,2)why(30,101)";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(2, try problem.part1());
}

test "part1 should work on third sample" {
    const allocator = std.testing.allocator;
    const input = "xmul(11,8)";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(88, try problem.part1());
}
