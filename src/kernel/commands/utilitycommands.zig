const stdio = @import("../lib/std/stdio.zig");
const sysutils = @import("../utils.zig");

pub fn verCmd() void {
    stdio.kprint("TinosZE version: ");
    stdio.kprint(sysutils.osVersion());
    stdio.kprint("Zig version: 0.16.0");
}
