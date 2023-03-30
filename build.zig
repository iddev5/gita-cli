const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "gita-cli",
        .root_source_file = .{ .path = "gita-cli.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.addModule("ay-arg", b.dependency("ay-arg", .{
        .target = target,
        .optimize = optimize,
    }).module("ay-arg"));
    if (exe.target.isWindows()) {
        exe.addIncludePath("deps");
        exe.addIncludePath("deps/WinToast/src");
        exe.addCSourceFile("deps/WinToast/src/wintoastlib.cpp", &.{});
        exe.addCSourceFile("deps/Toast.cpp", &.{});
    } else {
        exe.linkSystemLibrary("libnotify");
        exe.linkSystemLibrary("c");
    }
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
