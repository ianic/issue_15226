const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dep_opts = .{ .target = target, .optimize = optimize };
    const tls_module = b.dependency("tls", dep_opts).module("tls");

    const binaries = [_][]const u8{
        "client",
        "server",
    };
    inline for (binaries) |name| {
        const source_file = "src/" ++ name ++ ".zig";
        const exe = b.addExecutable(.{
            .name = name,
            .root_source_file = b.path(source_file),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("tls", tls_module);
        b.installArtifact(exe);
    }
}
