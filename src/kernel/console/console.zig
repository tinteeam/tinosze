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
                stdio.kprintln("TinosZE version: ");
                stdio.kprintln(@import("../utils/VersionUtils.zig").GetOsVersion());

                stdio.kprintln("Zig version: ");
                stdio.kprintln(@import("../utils/VersionUtils.zig").GetZigVersion());

                stdio.kprintln("Serial driver version: ");
                stdio.kprintln(@import("../utils/VersionUtils.zig").GetSerialDriverVersion());

                stdio.kprintln("Keyboard driver version: ");
                stdio.kprintln(@import("../utils/VersionUtils.zig").GetKeyboardDriverVersion());

                stdio.kprintln("Physical Memory Manager version: ");
                stdio.kprintln(@import("../utils/VersionUtils.zig").GetPmmVersion());

                stdio.kprintln("Virtual Memory Manager version: ");
                stdio.kprintln(@import("../utils/VersionUtils.zig").GetVmmVersion());
            } else if (stdio.strcmp(buffer[0..pos :0], "help") == 0) {
                stdio.kprintln("Available commands:");
                stdio.kprintln("ver - Show version information");
                stdio.kprintln("help - Show this help message");
                stdio.kprintln("hlt - Halt the system");
                stdio.kprintln("meminfo - Show memory information");
            } else if (stdio.strcmp(buffer[0..pos :0], "hlt") == 0) {
                stdio.kprint("Halting the system...");
                @import("../serial.zig").writeString("System is halting...");
                while (true) {
                    asm volatile ("cli; hlt");
                }
            } else if (stdio.strcmp(buffer[0..pos :0], "meminfo") == 0) {
                @import("../commands/meminfo.zig").meminfo();
            } else {
                if (pos > 0) {
                    stdio.kprint("Unknown command: ");
                    stdio.kprint(buffer[0..pos :0]);
                }
            }

            pos = 0;
            buffer[0] = 0;

            stdio.putChar('>');
        } else if (c != 0 and pos < buffer.len - 1) {
            buffer[pos] = c;
            pos += 1;
            buffer[pos] = 0;

            stdio.putChar(c);
        }
    }
}
