const std = @import("std");
const mem = std.mem;

const Data = struct {
    start_block: u64,
    size: u64,
    file_id: ?u64,

    pub fn sum(this: *const @This()) ?u64 {
        if (this.file_id == null) {
            return null;
        }

        if (this.file_id == 0) {
            return 0;
        }

        var s: u64 = 0;
        const start: usize = @intCast(this.start_block);
        const end: usize = start + @as(usize, @intCast(this.size));
        for (start..end) |block_id| {
            s += @as(u64, @intCast(block_id)) * this.file_id.?;
        }

        return s;
    }
};

const List = std.DoublyLinkedList(Data);

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?u64 {
    var list = List{};
    defer this.freeList(&list);

    try this.parse(&list);
    try this.eliminateSpace(&list);

    return calcChecksum(&list);
}

pub fn part2(this: *const @This()) !?u64 {
    var list = List{};
    defer this.freeList(&list);

    try this.parse(&list);
    try this.eliminateSpaceWholeFiles(&list);

    return calcChecksum(&list);
}

fn eliminateSpaceWholeFiles(this: *const @This(), list: *List) !void {
    var file_it = findPrevFile(list.last);
    while (file_it) |file_node| {
        while (true) {
            file_it = findPrevFile(file_it.?.prev);

            if (file_it == null) {
                break;
            }

            if (file_it.?.data.file_id == file_node.data.file_id.? - 1) {
                break;
            }
        }

        var it = list.first;
        while (it) |node| {
            it = node.next;
            if (node.data.file_id != null) {
                if (node.data.file_id.? == file_node.data.file_id.?) {
                    break;
                }

                continue;
            }

            if (node.data.size < file_node.data.size) {
                continue;
            }

            node.data.file_id = file_node.data.file_id;
            file_node.data.file_id = null;

            if (node.data.size > file_node.data.size) {
                const new_blank = try this.allocator.create(List.Node);
                new_blank.data = Data{
                    .file_id = null,
                    .size = node.data.size - file_node.data.size,
                    .start_block = node.data.start_block + file_node.data.size,
                };

                node.data.size = file_node.data.size;

                list.insertAfter(node, new_blank);
            }

            break;
        }
    }
}

fn eliminateSpace(this: *const @This(), list: *List) !void {
    var blank_it = findNextBlank(list.first);
    var file_it = findPrevFile(list.last);

    while (true) {
        if (blank_it == null or file_it == null) {
            break;
        }

        const blank_node = blank_it.?;
        const file_node = file_it.?;

        if (blank_node.data.size == file_node.data.size) {
            file_it = findPrevFile(file_node.prev);
            blank_it = findNextBlank(blank_node.next);

            blank_node.data.file_id = file_node.data.file_id;
            list.remove(file_node);
            this.allocator.destroy(file_node);
            this.destroyTrailingBlanks(list);
        } else if (blank_node.data.size < file_node.data.size) {
            blank_it = findNextBlank(blank_node.next);

            blank_node.data.file_id = file_node.data.file_id;
            file_node.data.size -= blank_node.data.size;
        } else {
            file_it = findPrevFile(file_node.prev);

            list.remove(file_node);
            list.insertBefore(blank_node, file_node);
            file_node.data.start_block = blank_node.data.start_block;
            blank_node.data.start_block += file_node.data.size;
            blank_node.data.size -= file_node.data.size;

            this.destroyTrailingBlanks(list);
        }
    }
}

fn destroyTrailingBlanks(this: *const @This(), list: *List) void {
    var it = list.last;
    while (it) |node| {
        it = node.prev;
        if (node.data.file_id == null) {
            list.remove(node);
            this.allocator.destroy(node);
        } else {
            break;
        }
    }
}

fn findNextBlank(start: ?*List.Node) ?*List.Node {
    var it = start;
    while (it) |node| {
        if (node.data.file_id == null) {
            return it;
        }

        it = node.next;
    }

    return null;
}

fn findPrevFile(start: ?*List.Node) ?*List.Node {
    var it = start;
    while (it) |node| {
        if (node.data.file_id != null) {
            return it;
        }

        it = node.prev;
    }

    return null;
}

fn calcChecksum(list: *List) u64 {
    var sum: u64 = 0;
    var it = list.first;
    while (it) |node| : ({
        it = node.next;
    }) {
        if (node.data.sum()) |s| {
            sum += s;
        }
    }

    return sum;
}

fn freeList(this: *const @This(), list: *List) void {
    var it = list.first;
    while (it) |node| {
        it = node.next;
        this.allocator.destroy(node);
    }
}

fn printList(list: *List) void {
    var it = list.first;
    while (it) |node| : ({
        it = node.next;
    }) {
        std.debug.print("start: {d}, size: {d}, id: {?}\n", .{ node.data.start_block, node.data.size, node.data.file_id });
    }

    std.debug.print("===================================\n\n", .{});
}

fn parse(this: *const @This(), list: *List) !void {
    var file_id: u64 = 0;
    var curr_block: u64 = 0;
    var is_empty = false;

    for (this.input) |char| {
        if (char < 48 or char > 57) continue;
        const size: u64 = @intCast(char - 48);

        if (size < 1) {
            is_empty = !is_empty;
            continue;
        }

        const node = try this.allocator.create(List.Node);
        node.data = Data{
            .start_block = curr_block,
            .size = size,
            .file_id = switch (is_empty) {
                false => file_id,
                true => null,
            },
        };

        list.append(node);

        if (!is_empty) {
            file_id += 1;
        }
        curr_block += size;
        is_empty = !is_empty;
    }
}

test "sample input" {
    const allocator = std.testing.allocator;
    const input = "2333133121414131402";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(1928, try problem.part1());
    try std.testing.expectEqual(2858, try problem.part2());
}
