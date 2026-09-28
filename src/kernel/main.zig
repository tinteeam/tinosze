const std = @import("std");
const stdio = @import("lib/std/stdio.zig");
const serial = @import("serial.zig");
const sconsole = @import("sconsole.zig");

var stack_bytes: [16384]u8 align(16) linksection(".bss") = undefined;
const MULTIBOOT2_MAGIC: u32 = 0xe85250d6;
const ARCH_X86: u32 = 0;
const HEADER_LENGTH: u32 = @sizeOf(MultibootHeader);

const CHECKSUM: u32 = -%(MULTIBOOT2_MAGIC + ARCH_X86 + HEADER_LENGTH);

const MultibootHeader = extern struct {
    magic: u32 = MULTIBOOT2_MAGIC,
    architecture: u32 = ARCH_X86,
    header_length: u32 = HEADER_LENGTH,
    checksum: u32 = CHECKSUM,
    type_end: u16 = 0,
    flags_end: u16 = 0,
    size_end: u32 = 8,
};

pub export var multiboot_header: MultibootHeader linksection(".multiboot2") = .{};

export fn _start() callconv(.c) noreturn {
    serial.init();
    serial.writeString("TinosZE Serial print TEST!");
    stdio.kprint("TinosZE print TEST!");

    serial.writeString("====================================\n");
    serial.writeString(" Welcome to TinosZE Serial Console! \n");
    serial.writeString("====================================\n");
    serial.writeString("> ");

    while (true) {
        sconsole.runIteration();
    }
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    _ = error_return_trace;
    _ = ret_addr;

    serial.writeString("KERNEL PANIC");
    serial.writeString("Kernel has paniced");

    serial.writeString(msg);
    while (true) {
        asm volatile ("hlt");
    }
}
