const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86,
        .os_tag = .freestanding,
        .abi = .none,
    });

    const optimize = b.standardOptimizeOption(.{});

    const kernel_obj = b.addObject(.{
        .name = "kernel",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/kernel/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    kernel_obj.root_module.code_model = .kernel;

    const copy_file = b.addInstallFile(kernel_obj.getEmittedBin(), "bin/kernel.o");
    b.getInstallStep().dependOn(&copy_file.step);
}
