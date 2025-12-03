const std = @import("std");
const mem = std.mem;

const List = std.DoublyLinkedList(u8);

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?u32 {
    var safe: u32 = 0;

    var it = mem.splitSequence(u8, this.input, "\n");
    var report = List{};

    while (it.next()) |line| {
        if (line.len < 1) {
            continue;
        }

        try this.readLine(line, &report);

        if (isSafe(&report, false)) {
            safe += 1;
        }

        this.freeList(&report);
    }

    return safe;
}

pub fn part2(this: *const @This()) !?u32 {
    var safe: u32 = 0;

    var it = mem.splitSequence(u8, this.input, "\n");
    var report = List{};

    while (it.next()) |line| {
        if (line.len < 1) {
            continue;
        }

        try this.readLine(line, &report);

        if (isSafe(&report, true)) {
            safe += 1;
        }

        this.freeList(&report);
    }

    return safe;
}

fn freeList(this: *const @This(), list: *List) void {
    while (list.pop()) |node| {
        this.allocator.destroy(node);
    }
}

fn readLine(this: *const @This(), line: []const u8, report: *List) !void {
    var line_it = mem.splitScalar(u8, line, ' ');

    var index: usize = 0;
    while (line_it.next()) |level| {
        const value = try std.fmt.parseInt(u8, level, 10);
        const node = try this.allocator.create(List.Node);

        node.data = value;
        report.append(node);
        index += 1;
    }

    return;
}

fn printLinkedList(report: List) void {
    var it = report.first;
    while (it) |node| : (it = node.next) {
        std.debug.print("{d} <-> ", .{node.data});
    }

    std.debug.print("NULL\n", .{});
}

fn isSafe(report: *List, can_skip: bool) bool {
    var increasing = true;
    var bad = false;

    var it = report.first;
    var index: usize = 0;
    while (it) |node| : ({
        it = node.next;
        index += 1;
    }) {
        if (node.next == null) {
            break;
        }

        const next = node.next.?;

        if (index == 0) {
            if (node.data > next.data) {
                increasing = false;
            }
        }

        var diff: u8 = 0;
        var bad_dir = false;
        if (node.data < next.data) {
            if (!increasing) {
                bad_dir = true;
            }

            diff = next.data - node.data;
        } else {
            if (increasing) {
                bad_dir = true;
            }

            diff = node.data - next.data;
        }

        if (bad_dir or diff < 1 or diff > 3) {
            bad = true;
            if (can_skip) {
                report.remove(node);
                var safe = isSafe(report, false);
                report.insertBefore(next, node);

                if (safe) {
                    return true;
                }

                report.remove(next);
                safe = isSafe(report, false);
                report.insertAfter(node, next);

                if (safe) {
                    return true;
                }
            } else {
                return false;
            }
        }
    }

    if (bad) {
        if (can_skip) {
            const node = report.first.?;
            // try removing first one
            report.remove(node);
            const res = isSafe(report, false);
            report.insertBefore(report.first.?, node);

            return res;
        }

        return false;
    }

    return true;
}

test "sample input" {
    const allocator = std.testing.allocator;
    const input = "7 6 4 2 1\n1 2 7 8 9\n9 7 6 2 1\n1 3 2 4 5\n8 6 4 4 1\n1 3 6 7 9\n";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(2, try problem.part1());
    try std.testing.expectEqual(4, try problem.part2());
}

test "isSafe returns true for increasing numbers" {
    const L = List;
    var list = L{};
    var a = L.Node{ .data = 1 };
    var b = L.Node{ .data = 2 };
    var c = L.Node{ .data = 4 };
    var d = L.Node{ .data = 7 };
    list.append(&a);
    list.append(&b);
    list.append(&c);
    list.append(&d);

    try std.testing.expect(isSafe(&list, false) == true);
}

test "isSafe returns true for decreasing numbers" {
    const L = List;
    var list = L{};
    var a = L.Node{ .data = 7 };
    var b = L.Node{ .data = 4 };
    var c = L.Node{ .data = 2 };
    var d = L.Node{ .data = 1 };
    list.append(&a);
    list.append(&b);
    list.append(&c);
    list.append(&d);

    try std.testing.expect(isSafe(&list, false) == true);
}

test "isSafe returns false for increasing then decreasing numbers" {
    const L = List;
    var list = L{};
    var a = L.Node{ .data = 1 };
    var b = L.Node{ .data = 2 };
    var c = L.Node{ .data = 1 };
    var d = L.Node{ .data = 7 };
    list.append(&a);
    list.append(&b);
    list.append(&c);
    list.append(&d);

    try std.testing.expect(isSafe(&list, false) == false);
}

test "isSafe returns false for decreasing then increasing numbers" {
    const L = List;
    var list = L{};
    var a = L.Node{ .data = 4 };
    var b = L.Node{ .data = 2 };
    var c = L.Node{ .data = 1 };
    var d = L.Node{ .data = 7 };
    list.append(&a);
    list.append(&b);
    list.append(&c);
    list.append(&d);

    try std.testing.expect(isSafe(&list, false) == false);
}

test "isSafe with skip returns true if only one number is switching direction" {
    const L = List;
    var list = L{};
    var a = L.Node{ .data = 4 };
    var b = L.Node{ .data = 2 };
    var c = L.Node{ .data = 1 };
    var d = L.Node{ .data = 7 };
    list.append(&a);
    list.append(&b);
    list.append(&c);
    list.append(&d);

    try std.testing.expect(isSafe(&list, true) == true);
}

test "isSafe with skip returns true if only one diff is out of range" {
    const L = List;
    var list = L{};
    var a = L.Node{ .data = 4 };
    var b = L.Node{ .data = 2 };
    var c = L.Node{ .data = 1 };
    var d = L.Node{ .data = 1 };
    list.append(&a);
    list.append(&b);
    list.append(&c);
    list.append(&d);

    try std.testing.expect(isSafe(&list, true) == true);
}

test "isSafe with skip returns false if only two numbers are switching direction" {
    const L = List;
    var list = L{};
    var a = L.Node{ .data = 4 };
    var b = L.Node{ .data = 5 };
    var c = L.Node{ .data = 3 };
    var d = L.Node{ .data = 4 };
    list.append(&a);
    list.append(&b);
    list.append(&c);
    list.append(&d);

    try std.testing.expect(isSafe(&list, true) == false);
}

test "isSafe with skip returns false if two diffs are out of range" {
    const L = List;
    var list = L{};
    var a = L.Node{ .data = 8 };
    var b = L.Node{ .data = 2 };
    var c = L.Node{ .data = 1 };
    var d = L.Node{ .data = 1 };
    list.append(&a);
    list.append(&b);
    list.append(&c);
    list.append(&d);

    try std.testing.expect(isSafe(&list, true) == false);
}

test "isSafe without skip returns false if only first is different" {
    const L = List;
    var list = L{};
    var a = L.Node{ .data = 6 };
    var b = L.Node{ .data = 9 };
    var c = L.Node{ .data = 8 };
    var d = L.Node{ .data = 7 };
    list.append(&a);
    list.append(&b);
    list.append(&c);
    list.append(&d);

    try std.testing.expect(isSafe(&list, false) == false);
}

test "isSafe with skip returns true if only first is different" {
    const L = List;
    var list = L{};
    var a = L.Node{ .data = 6 };
    var b = L.Node{ .data = 9 };
    var c = L.Node{ .data = 8 };
    var d = L.Node{ .data = 7 };
    list.append(&a);
    list.append(&b);
    list.append(&c);
    list.append(&d);

    try std.testing.expect(isSafe(&list, true) == true);
}
