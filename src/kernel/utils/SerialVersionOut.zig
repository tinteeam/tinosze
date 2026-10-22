const stdio = @import("../lib/std/stdio.zig");
const versionUtils = @import("VersionUtils.zig");
const serial = @import("../serial.zig");

pub fn VersionToSerialOutput(shouldPrintHello: bool) void {
    const osVersion = versionUtils.GetOsVersion();
    const zigVersion = versionUtils.GetZigVersion();
    const serialDriverVersion = versionUtils.GetSerialDriverVersion();
    const keyboardDriverVersion = versionUtils.GetKeyboardDriverVersion();
    const pmmVersion = versionUtils.GetPmmVersion();
    const vmmVersion = versionUtils.GetVmmVersion();

    if (shouldPrintHello) {
        serial.writeString("Hello from TinosZE kernel's Serial Driver!");
    }

    serial.writeString("OS Version: ");
    serial.writeString(osVersion);

    serial.writeString("Zig Version: ");
    serial.writeString(zigVersion);

    serial.writeString("Serial Driver Version: ");
    serial.writeString(serialDriverVersion);

    serial.writeString("Keyboard Driver Version: ");
    serial.writeString(keyboardDriverVersion);

    serial.writeString("PMM Version: ");
    serial.writeString(pmmVersion);

    serial.writeString("VMM Version: ");
    serial.writeString(vmmVersion);
}
