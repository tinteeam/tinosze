const stdio = @import("../../lib/std/stdio.zig");

pub fn readChar() u8 {
    const scancodeTable: [128]u8 = .{
        0,    27,  '1', '2', '3', '4', '5', '6', '7', '8', '9',  '0', '-', '=',  stdio.BACKSPACE,
        '\t', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p',  '[', ']', '\n', 0,
        'a',  's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '`', 0,   '\\', 'z',
        'x',  'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0,   '*',  0,   ' ', 0,    0,
        0,    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,    0,
        0,    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,    0,
        0,    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,    0,
        0,    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,    0,
        0,    0,   0,   0,   0,   0,   0,   0,
    };

    while ((stdio.inb(0x64) & 1) == 0) {
        asm volatile ("pause");
    }

    const sc: u8 = stdio.inb(0x60);

    if ((sc & 0x80) != 0) {
        return 0;
    }

    return scancodeTable[sc];
}
