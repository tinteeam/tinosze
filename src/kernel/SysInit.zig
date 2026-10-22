const stdio = @import("lib/std/stdio.zig");
const pmm = @import("mm/pmm.zig");
const vmm = @import("mm/vmm.zig");

extern var kernel_start: anyopaque;
extern var kernel_end: anyopaque;

pub const MULTIBOOT_MEMORY_AVAILABLE: u32 = 1;
const MULTIBOOT_TAG_TYPE_END: u32 = 0;
const MULTIBOOT_TAG_TYPE_MMAP: u32 = 6;
var total_memory: u64 = 0;

const MultibootInfoHeader = extern struct {
    total_size: u32,
    reserved: u32,
};

const MultibootTag = extern struct {
    typ: u32,
    size: u32,
};

const MmapTag = extern struct {
    typ: u32,
    size: u32,
    entry_size: u32,
    entry_version: u32,
};

const MmapEntry = extern struct {
    addr: u64,
    len: u64,
    typ: u32,
    reserved: u32,
};

pub fn detectMem(mboot_info: *anyopaque) void {
    const info: *const MultibootInfoHeader = @ptrCast(@alignCast(mboot_info));
    var current_addr = @intFromPtr(info) + @sizeOf(MultibootInfoHeader);
    const end_addr = @intFromPtr(info) + info.total_size;

    while (current_addr < end_addr) {
        const tag: *const MultibootTag = @ptrFromInt(current_addr);
        if (tag.typ == MULTIBOOT_TAG_TYPE_END) break;

        if (tag.typ == MULTIBOOT_TAG_TYPE_MMAP) {
            const mmap: *const MmapTag = @ptrFromInt(current_addr);
            var entry_addr = current_addr + @sizeOf(MmapTag);
            const tag_end = current_addr + mmap.size;

            while (entry_addr + mmap.entry_size <= tag_end) : (entry_addr += mmap.entry_size) {
                const entry: *const MmapEntry = @ptrFromInt(entry_addr);
                if (entry.typ == MULTIBOOT_MEMORY_AVAILABLE) {
                    total_memory += entry.len;
                    pmm.pmmAddRegion(entry.addr, entry.len);
                }
            }
        }

        current_addr += (tag.size + 7) & ~@as(usize, 7);
    }
}

pub fn memInit() void {
    const start = @intFromPtr(&kernel_start);
    const end = @intFromPtr(&kernel_end);

    const kernel_size = end - start;

    stdio.kprint("[PMM] Reserving kernel memory space....\n");

    pmm.pmmReserveRegion(start, kernel_size);

    stdio.kprint("Usable memory:");
    stdio.printU64(total_memory / (1024 * 1024));
    stdio.kprint(" MiB\n");

    vmm.vmmInit();

    stdio.kprint("[PMM] Kernel memory space reserved successfully!\n");
}
