const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const http = std.http;
const fmt = std.fmt;
const Build = std.Build;
const LazyPath = Build.LazyPath;
const Step = Build.Step;
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const builtin = @import("builtin");

comptime {
    const req = "0.14.1";
    const current_zig = builtin.zig_version;
    const required_zig = std.SemanticVersion.parse(req) catch unreachable;
    if (current_zig.order(required_zig) != .eq) {
        const error_message =
            \\Build requires development build {s}
        ;
        @compileError(std.fmt.comptimePrint(error_message, .{req}));
    }
}

const INPUT_DIR = "input";
const SRC_DIR = "src";

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    for (1..26) |day| {
        const exe = b.addExecutable(.{
            .name = try fmt.allocPrint(
                b.allocator,
                "day{d}",
                .{day},
            ),
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });

        exe.root_module.addAnonymousImport(
            "problem",
            .{
                .root_source_file = b.path(
                    try fs.path.join(
                        b.allocator,
                        &[_][]const u8{
                            SRC_DIR,
                            "days",
                            try fmt.allocPrint(
                                b.allocator,
                                "day{d}.zig",
                                .{day},
                            ),
                        },
                    ),
                ),
            },
        );
        exe.root_module.addAnonymousImport(
            "input",
            .{
                .root_source_file = b.path(
                    try fs.path.join(
                        b.allocator,
                        &[_][]const u8{
                            INPUT_DIR,
                            try fmt.allocPrint(
                                b.allocator,
                                "day{d}.txt",
                                .{day},
                            ),
                        },
                    ),
                ),
            },
        );

        b.installArtifact(exe);
    }
}
