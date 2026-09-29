const std = @import("std");
const serial = @import("serial.zig");
const stdio = @import("lib/std/stdio.zig");
const utilityCmds = @import("commands/utilitycommands.zig");

var cmd_buffer: [64]u8 = undefined;
var cmd_len: usize = 0;

pub fn runIteration() void {
    const c = serial.readChar();

    if (c == '\r' or c == '\n') {
        if (cmd_len == 0) {
            serial.writeString("\n> ");
            return;
        }

        serial.writeString("\n");
        executeCommand(cmd_buffer[0..cmd_len]);

        cmd_len = 0;
        serial.writeString("> ");
    }
    // Käsitellään Backspace
    else if (c == 8 or c == 127) {
        if (cmd_len > 0) {
            cmd_len -= 1;
            serial.writeString("\x08 \x08");
        }
    } else if (cmd_len < cmd_buffer.len - 1) {
        cmd_buffer[cmd_len] = c;
        cmd_len += 1;
        serial.writeByte(c);
    }
}

fn executeCommand(cmd: []const u8) void {
    if (std.mem.eql(u8, cmd, "help")) {
        serial.writeString("TinosZE Debug Console v0.1\n");
        serial.writeString("Available commands: help, ping, halt\n");
    } else if (std.mem.eql(u8, cmd, "ping")) {
        serial.writeString("PONG! Kernel is alive and kicking.\n");
    } else if (std.mem.eql(u8, cmd, "halt")) {
        stdio.kprint("SCONSOLE: Serial console requested a system halt");
        serial.writeString("System halting safely...\n");
        while (true) {
            asm volatile ("cli; hlt");
        }
    } else if (std.mem.eql(u8, cmd, "ver")) {
        utilityCmds.verCmd();
    } else {
        serial.writeString("Unknown command. Type 'help' for options.\n");
    }
}
