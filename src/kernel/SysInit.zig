const stdio = @import("lib/std/stdio.zig");
const pmm = @import("mm/pmm.zig");

extern var kernel_start: anyopaque;
extern var kernel_end: anyopaque;

pub fn memInit() void {
    const start = @intFromPtr(&kernel_start);
    const end = @intFromPtr(&kernel_end);

    const kernel_size = end - start;

    stdio.kprint("[PMM] Reserving kernel memory space....\n");

    pmm.pmmReserveRegion(start, kernel_size);

    stdio.kprint("[PMM] Kernel memory space reserved successfully!\n");
}
