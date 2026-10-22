const std = @import("std");
const stdio = @import("lib/std/stdio.zig");
const serial = @import("serial.zig");
const console = @import("console/console.zig");
const pmm = @import("mm/pmm.zig");

pub export var stack_bytes: [16384]u8 align(16) linksection(".bss") = undefined;
pub export var pml4_table: [512]u64 align(4096) linksection(".bss") = [_]u64{0} ** 512;
pub export var pdpt_table: [512]u64 align(4096) linksection(".bss") = [_]u64{0} ** 512;
pub export var pd_table: [512]u64 align(4096) linksection(".bss") = [_]u64{0} ** 512;

const MULTIBOOT2_MAGIC: u32 = 0xe85250d6;
const ARCH_X86: u32 = 0;
const HEADER_LENGTH: u32 = @sizeOf(MultibootHeader);

const CHECKSUM: u32 = -%(MULTIBOOT2_MAGIC + ARCH_X86 + HEADER_LENGTH);
const MULTIBOOT2_BOOTLOADER_MAGIC: u32 = 0x36d76289;

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

pub export fn kernel_main(magic: u32, mboot_info: *anyopaque) callconv(.c) noreturn {
    serial.init();

    pmm.pmmInit();

    if (magic == MULTIBOOT2_BOOTLOADER_MAGIC) {
        @import("SysInit.zig").detectMem(mboot_info);
    } else {
        stdio.kprint("[BOOT] Invalid Multiboot2 magic\n");
    }

    @import("SysInit.zig").memInit();

    serial.writeString("TinosZE Serial print TEST!");

    stdio.kprint("Type 'help' for a list of commands.\n");

    while (true) {
        console.run();
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

pub export fn memset(s: [*]u8, c: i32, n: usize) callconv(.c) [*]u8 {
    var i: usize = 0;
    while (i < n) : (i += 1) {
        s[i] = @intCast(c & 0xFF);
    }
    return s;
}

pub export fn memcpy(dest: [*]u8, src: [*]const u8, n: usize) callconv(.c) [*]u8 {
    var i: usize = 0;
    while (i < n) : (i += 1) {
        dest[i] = src[i];
    }
    return dest;
}

pub export fn memmove(dest: [*]u8, src: [*]const u8, n: usize) callconv(.c) [*]u8 {
    if (@intFromPtr(dest) < @intFromPtr(src)) {
        var i: usize = 0;
        while (i < n) : (i += 1) {
            dest[i] = src[i];
        }
    } else {
        var i: usize = n;
        while (i > 0) {
            i -= 1;
            dest[i] = src[i];
        }
    }
    return dest;
}

pub export fn __zig_probe_stack() callconv(.naked) void {
    asm volatile (
        \\ret
    );
}

pub export fn __udivdi3(dividend: u64, divisor: u64) callconv(.c) u64 {
    if (divisor == 0) {
        @panic("division by zero");
    }

    var quotient: u64 = 0;
    var remainder: u64 = 0;
    var bit: u7 = 64;

    while (bit > 0) {
        bit -= 1;
        const shift: u6 = @intCast(bit);
        remainder = (remainder << 1) | ((dividend >> shift) & 1);
        if (remainder >= divisor) {
            remainder -= divisor;
            quotient |= @as(u64, 1) << shift;
        }
    }

    return quotient;
}
