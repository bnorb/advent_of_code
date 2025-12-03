const std = @import("std");
const mem = std.mem;

const GateType = enum { AND, OR, XOR };
const ValueMap = std.StringHashMap(?bool);
const GateList = std.DoublyLinkedList(Gate);
const GateMap = std.StringHashMap(std.ArrayList(*GateList.Node));

const Module = struct {
    prev_carry: []const u8,
    x_in: []const u8,
    y_in: []const u8,
    out: []const u8,

    input_xor: ?[]const u8 = null,
    prev_carry_and: ?[]const u8 = null,
    input_and: ?[]const u8 = null,
    carry: ?[]const u8 = null,

    pub fn validateInnerWiring(this: *@This(), gate_map: *GateMap) bool {
        const input_xor = findGateByInputs(this.x_in, this.y_in, GateType.XOR, gate_map);
        if (input_xor == null) return false;
        this.input_xor = input_xor.?.data.out;

        const input_and = findGateByInputs(this.x_in, this.y_in, GateType.AND, gate_map);
        if (input_and == null) return false;
        this.input_and = input_and.?.data.out;

        const prev_carry_and = findGateByInputs(this.prev_carry, this.input_xor.?, GateType.AND, gate_map);
        if (prev_carry_and == null) return false;
        this.prev_carry_and = prev_carry_and.?.data.out;

        const carry = findGateByInputs(this.prev_carry_and.?, this.input_and.?, GateType.OR, gate_map);
        if (carry == null) return false;
        this.carry = carry.?.data.out;

        const prev_carry_xor = findGateByInputs(this.prev_carry, this.input_xor.?, GateType.XOR, gate_map);
        if (prev_carry_xor == null) return false;
        if (!mem.eql(u8, prev_carry_xor.?.data.out, this.out)) return false;

        return true;
    }

    pub fn print(this: *const @This()) void {
        std.debug.print("==================================\n", .{});
        std.debug.print("x_in: {s}\ny_in: {s}\nout: {s}\nprev_carry: {s}\n\n", .{ this.x_in, this.y_in, this.out, this.prev_carry });
        std.debug.print("input_xor: {s}\n", .{if (this.input_xor != null) this.input_xor.? else "null"});
        std.debug.print("prev_carry_and: {s}\n", .{if (this.prev_carry_and != null) this.prev_carry_and.? else "null"});
        std.debug.print("input_and: {s}\n", .{if (this.input_and != null) this.input_and.? else "null"});
        std.debug.print("carry: {s}\n", .{if (this.carry != null) this.carry.? else "null"});
        std.debug.print("==================================\n", .{});
    }

    fn findGateByInputs(in1: []const u8, in2: []const u8, gate_type: GateType, gate_map: *GateMap) ?*GateList.Node {
        if (gate_map.getPtr(in1)) |potentials| {
            for (potentials.items) |node| {
                const inputs_match = (mem.eql(u8, node.data.in1, in1) and mem.eql(u8, node.data.in2, in2)) or (mem.eql(u8, node.data.in1, in2) and mem.eql(u8, node.data.in2, in1));
                if (inputs_match and node.data.gate_type == gate_type) {
                    return node;
                }
            }
        }

        return null;
    }

    pub fn getNextCarryWire(this: *const @This(), gate_map: *GateMap) []const u8 {
        const gates_of_prev: *std.ArrayList(*GateList.Node) = gate_map.getPtr(this.prev_carry).?;
        for (gates_of_prev.items) |node| {
            if (node.data.out == this.out) {}
        }
    }
};

const Gate = struct {
    in1: []const u8,
    in2: []const u8,
    out: []const u8,
    gate_type: GateType,

    pub fn doCalc(this: *const @This(), valueMap: *ValueMap) !bool {
        if (valueMap.get(this.out).? != null) {
            return true;
        }

        const in1_val = valueMap.get(this.in1).?;
        const in2_val = valueMap.get(this.in2).?;

        if (in1_val == null or in2_val == null) {
            return false;
        }

        try valueMap.put(this.out, this.calc(in1_val.?, in2_val.?));

        return true;
    }

    fn calc(this: *const @This(), in1_val: bool, in2_val: bool) bool {
        return switch (this.gate_type) {
            GateType.AND => in1_val and in2_val,
            GateType.OR => in1_val or in2_val,
            GateType.XOR => (in1_val and !in2_val) or (!in1_val and in2_val),
        };
    }
};

const Device = struct {
    arena: *std.heap.ArenaAllocator,
    values: ValueMap,
    gates: GateList,
    gate_map: GateMap,
    output_msb_place: usize,

    pub fn init(arena: *std.heap.ArenaAllocator, input: []const u8) !Device {
        const allocator = arena.allocator();
        var values = ValueMap.init(allocator);
        var output_msb_place: usize = 0;
        var gates = GateList{};
        var gate_map = GateMap.init(allocator);

        var parts = mem.splitSequence(u8, input, "\n\n");

        try parseInputs(&values, parts.next().?);
        try parseGates(allocator, &values, &gates, &gate_map, &output_msb_place, parts.next().?);

        return Device{
            .arena = arena,
            .values = values,
            .output_msb_place = output_msb_place,
            .gates = gates,
            .gate_map = gate_map,
        };
    }

    pub fn findErrors(this: *@This()) !void {
        const allocator = this.arena.allocator();

        var carry = Module.findGateByInputs("x00", "y00", GateType.AND, &this.gate_map).?.data.out;
        var module_idx: u8 = 1;

        while (module_idx < 45) : (module_idx += 1) {
            var module = Module{
                .x_in = try std.fmt.allocPrint(allocator, "x{d:0>2}", .{module_idx}),
                .y_in = try std.fmt.allocPrint(allocator, "y{d:0>2}", .{module_idx}),
                .out = try std.fmt.allocPrint(allocator, "z{d:0>2}", .{module_idx}),
                .prev_carry = carry,
            };

            if (!module.validateInnerWiring(&this.gate_map)) {
                std.debug.print("incorrect wiring in module {d}\n", .{module_idx});
                module.print();
                return;
            }

            carry = module.carry.?;
        }
    }

    pub fn simulate(this: *@This()) !void {
        var curr_gate = this.gates.first;

        while (curr_gate) |gate| {
            const calculated = try gate.data.doCalc(&this.values);
            const next = gate.next;
            if (calculated) {
                this.gates.remove(gate);
            }

            if (next) |_| {
                curr_gate = next;
            } else {
                curr_gate = this.gates.first;
            }
        }
    }

    pub fn getOutput(this: *const @This()) !u64 {
        const allocator = this.arena.allocator();
        var out_num: []u8 = try allocator.alloc(u8, this.output_msb_place + 1);
        defer allocator.free(out_num);

        var z_bit: usize = 0;
        while (z_bit <= this.output_msb_place) : (z_bit += 1) {
            const out_name = try std.fmt.allocPrint(allocator, "z{d:0>2}", .{z_bit});
            const val = this.values.get(out_name).?.?;
            out_num[this.output_msb_place - z_bit] = if (val) '1' else '0';
        }

        return try std.fmt.parseInt(u64, out_num, 2);
    }

    fn parseGates(allocator: mem.Allocator, values: *ValueMap, gates: *GateList, gate_map: *GateMap, output_msb_place: *usize, input: []const u8) !void {
        var it = mem.splitSequence(u8, input, "\n");
        while (it.next()) |line| {
            if (line.len < 1) continue;

            var parts = mem.splitSequence(u8, line, " -> ");
            const in_part = parts.next().?;
            const out = parts.next().?;

            var in_it = mem.splitScalar(u8, in_part, ' ');
            const in1 = in_it.next().?;
            const gate_type = in_it.next().?;
            const in2 = in_it.next().?;

            var node = try allocator.create(GateList.Node);
            node.data = Gate{
                .in1 = in1,
                .in2 = in2,
                .out = out,
                .gate_type = if (mem.eql(u8, gate_type, "AND")) GateType.AND else if (mem.eql(u8, gate_type, "OR")) GateType.OR else GateType.XOR,
            };

            gates.append(node);
            try addToGateMap(allocator, in1, gate_map, node);
            try addToGateMap(allocator, in2, gate_map, node);

            if (!values.contains(in1)) {
                try values.put(in1, null);
            }

            if (!values.contains(in2)) {
                try values.put(in2, null);
            }

            if (!values.contains(out)) {
                try values.put(out, null);
            }

            if (out[0] == 'z') {
                const z_num = try std.fmt.parseInt(usize, out[1..], 10);
                if (z_num > output_msb_place.*) output_msb_place.* = z_num;
            }
        }
    }

    fn addToGateMap(allocator: mem.Allocator, in: []const u8, gate_map: *GateMap, gate_node: *GateList.Node) !void {
        if (gate_map.getPtr(in)) |list| {
            try list.append(gate_node);
            return;
        }

        var list = std.ArrayList(*GateList.Node).init(allocator);
        try list.append(gate_node);
        try gate_map.put(in, list);
    }

    fn parseInputs(values: *ValueMap, input: []const u8) !void {
        var it = mem.splitSequence(u8, input, "\n");
        while (it.next()) |line| {
            if (line.len < 1) continue;

            const name = line[0..3];
            const value: ?bool = if (line[5] == '1') true else false;

            try values.put(name, value);
        }
    }
};

input: []const u8,
allocator: mem.Allocator,

pub fn part1(this: *const @This()) !?u64 {
    var arena = std.heap.ArenaAllocator.init(this.allocator);
    defer arena.deinit();

    var device = try Device.init(&arena, this.input);
    try device.simulate();

    return try device.getOutput();
}

pub fn part2(this: *const @This()) !?i64 {
    var arena = std.heap.ArenaAllocator.init(this.allocator);
    defer arena.deinit();

    var device = try Device.init(&arena, this.input);
    try device.findErrors();

    // run with OG input, fix each error by swapping the wires in the faulty module
    // after 4 swaps it's done

    // dkr <-> z05
    // htp <-> z15
    // hhh <-> z20
    // ggk <-> rhv

    // dkr,ggk,hhh,htp,rhv,z05,z15,z20

    return null;
}

test "sample input" {
    const allocator = std.testing.allocator;
    const input = "x00: 1\nx01: 0\nx02: 1\nx03: 1\nx04: 0\ny00: 1\ny01: 1\ny02: 1\ny03: 1\ny04: 1\n\nntg XOR fgs -> mjb\ny02 OR x01 -> tnw\nkwq OR kpj -> z05\nx00 OR x03 -> fst\ntgd XOR rvg -> z01\nvdt OR tnw -> bfw\nbfw AND frj -> z10\nffh OR nrd -> bqk\ny00 AND y03 -> djm\ny03 OR y00 -> psh\nbqk OR frj -> z08\ntnw OR fst -> frj\ngnj AND tgd -> z11\nbfw XOR mjb -> z00\nx03 OR x00 -> vdt\ngnj AND wpb -> z02\nx04 AND y00 -> kjc\ndjm OR pbm -> qhw\nnrd AND vdt -> hwm\nkjc AND fst -> rvg\ny04 OR y02 -> fgs\ny01 AND x02 -> pbm\nntg OR kjc -> kwq\npsh XOR fgs -> tgd\nqhw XOR tgd -> z09\npbm OR djm -> kpj\nx03 XOR y03 -> ffh\nx00 XOR y04 -> ntg\nbfw OR bqk -> z06\nnrd XOR fgs -> wpb\nfrj XOR qhw -> z04\nbqk OR frj -> z07\ny03 OR x01 -> nrd\nhwm AND bqk -> z03\ntgd XOR rvg -> z12\ntnw OR pbm -> gnj\n";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(2024, try problem.part1());
    try std.testing.expectEqual(null, try problem.part2());
}
