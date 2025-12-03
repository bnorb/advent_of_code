const std = @import("std");
const fs = std.fs;
const io = std.io;
const heap = std.heap;

const Problem = @import("problem");

fn printSolution(solution: anytype) !void {
    try io.getStdOut().writer().print(switch (@TypeOf(solution)) {
        []const u8 => "{s}",
        []u8 => "{s}",
        else => "{any}",
    } ++ "\n", .{solution});
}

pub fn main() !void {
    var arena = heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);

    if (args.len < 2) {
        return error.MissingPart;
    }

    const part: u8 = try std.fmt.parseInt(u8, args[1], 10);
    if (part != 1 and part != 2) {
        return error.InvalidPart;
    }

    const problem = Problem{
        .input = @embedFile("input"),
        .allocator = allocator,
    };

    if (part == 1) {
        if (try problem.part1()) |solution|
            try printSolution(solution);
    } else {
        if (try problem.part2()) |solution|
            try printSolution(solution);
    }
}
