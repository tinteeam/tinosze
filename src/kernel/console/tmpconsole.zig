const stdio = @import("../lib/std/stdio.zig");
const kb = @import("../drivers/keyboard/kb.zig");

pub fn tempconsole() void {
    var buffer: [128:0]u8 = undefined;
    var pos: usize = 0;

    while (true) {
        const c: u8 = kb.readChar();

        if (c == stdio.BACKSPACE) {
            if (pos > 0) {
                pos -= 1;
                buffer[pos] = 0;

                stdio.putChar(stdio.BACKSPACE);
                stdio.putChar(' ');
                stdio.putChar(stdio.BACKSPACE);
            }
        } else if (c == '\n') {
            buffer[pos] = 0;

            stdio.kprint("\n");

            if (stdio.strcmp(&buffer, "test") == 0) {
                stdio.kprint("TEST");
            }

            pos = 0;
            buffer[0] = 0;
        } else if (pos < buffer.len - 1) {
            buffer[pos] = c;
            pos += 1;
            buffer[pos] = 0;

            stdio.putChar(c);
        }
    }
}
