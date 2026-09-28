const std = @import("std");
const stdio = @import("lib/std/stdio.zig");

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
    stdio.putChar('T');
    stdio.putChar('e');
    stdio.putChar('s');
    stdio.putChar('t');
    stdio.putChar('\n');

    while (true) {
        asm volatile ("hlt");
    }
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    _ = msg;
    _ = error_return_trace;
    _ = ret_addr;
    while (true) {
        asm volatile ("hlt");
    }
}
