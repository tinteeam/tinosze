const stdio = @import("../lib/std/stdio.zig");

pub fn GetOsVersion() []const u8 {
    return "0.1 alpha2";
}

pub fn GetZigVersion() []const u8 {
    return "0.16.0";
}

pub fn GetSerialDriverVersion() []const u8 {
    return "0.1 alpha";
}

pub fn GetKeyboardDriverVersion() []const u8 {
    return "0.1 alpha";
}
