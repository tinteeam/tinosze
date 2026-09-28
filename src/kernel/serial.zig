const stdio = @import("lib/std/stdio.zig");

const COM1: u16 = 0x3F8;

pub fn init() void {
    stdio.kprint("SERIAL: Starting serial");
    stdio.outb(COM1 + 1, 0x00); // Disable interrupts
    stdio.outb(COM1 + 3, 0x80); // Enable DLAB
    stdio.outb(COM1 + 0, 0x03); // Baud divisor low: 3 = 38400
    stdio.outb(COM1 + 1, 0x00); // Baud divisor high
    stdio.outb(COM1 + 3, 0x03); // 8 bits, no parity, 1 stop bit
    stdio.outb(COM1 + 2, 0xC7); // Enable FIFO, clear, 14-byte threshold
    stdio.outb(COM1 + 4, 0x0B); // IRQs enabled, RTS/DSR set
    stdio.kprint("SERIAL: Serial started on COM1");
}

pub fn writeByte(c: u8) void {
    while ((stdio.inb(COM1 + 5) & 0x20) == 0) {}
    stdio.outb(COM1, c);
}

pub fn writeString(str: []const u8) void {
    for (str) |c| {
        writeByte(c);
    }
    writeByte('\n');
}
