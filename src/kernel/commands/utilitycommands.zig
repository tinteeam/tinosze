const stdio = @import("../lib/std/stdio.zig");
const sysutils = @import("../utils.zig");

pub fn verCmd() void {
    const sysVer = sysutils.osVersion();
    stdio.kprint("TinosZE version: ");
    stdio.kprint(sysVer);
    stdio.kprint("Ziglang: 0.16.0");
}
