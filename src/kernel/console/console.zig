const stdio = @import("../lib/std/stdio.zig");
const kb = @import("../drivers/keyboard/kb.zig");

pub fn run() void {
    var buffer: [128:0]u8 = undefined;
    var pos: usize = 0;

    stdio.putChar('>');
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

            if (stdio.strcmp(buffer[0..pos :0], "ver") == 0) {
                stdio.kprint("TinosZE version: 0.1 alpha");
                stdio.kprint("Zig version: 0.16.0");
            } else if (stdio.strcmp(buffer[0..pos :0], "help") == 0) {
                stdio.kprint("Available commands:");
                stdio.kprint("ver - Show version information");
                stdio.kprint("help - Show this help message");
            } else {
                stdio.kprint("Unknown command: ");
                stdio.kprint(buffer[0..pos :0]);
            }

            pos = 0;
            buffer[0] = 0;
        } else if (c != 0 and pos < buffer.len - 1) {
            buffer[pos] = c;
            pos += 1;
            buffer[pos] = 0;

            stdio.putChar(c);
        }
    }
}
