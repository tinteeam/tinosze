const pmm = @import("../mm/pmm.zig");
const stdio = @import("../lib/std/stdio.zig");

pub fn meminfo() void {
    const free: u64 = pmm.pmmGetFreePages();
    const total: u64 = pmm.pmmGetTotalPages();
    const used: u64 = total - free;

    if (total == 0) {
        stdio.kprintln("Memory Information unavailable: no pages detected");
        return;
    }

    const free_mb: u64 = free * 4 / 1024;
    const total_mb: u64 = total * 4 / 1024;
    const used_mb: u64 = used * 4 / 1024;
    const used_percent: u64 = (used * 100) / total;

    stdio.kprint("Memory Information:\n");
    stdio.kprint("Total Memory: ");
    stdio.printU64(total_mb);
    stdio.kprint(" MB\n");
    stdio.kprint("Used Memory: ");
    stdio.printU64(used_mb);
    stdio.kprint(" MB (");
    stdio.printU64(used_percent);
    stdio.kprint("%)\n");
    stdio.kprint("Free Memory: ");
    stdio.printU64(free_mb);
    stdio.kprint(" MB\n");
}
