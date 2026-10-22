const stdio = @import("../lib/std/stdio.zig");

pub const PMM_PAGE_SIZE: u64 = 4096;
pub const MAX_PHYSICAL_MEMORY: u64 = 64 * 1024 * 1024 * 1024;
pub const MAX_PAGES: u64 = MAX_PHYSICAL_MEMORY / PMM_PAGE_SIZE;
pub const BITMAP_SIZE: u64 = (MAX_PAGES + 7) / 8;

var bitmap: [BITMAP_SIZE]u8 linksection(".data.boot") = undefined;
var total_pages: u64 linksection(".data.boot") = 0;
var free_pages: u64 linksection(".data.boot") = 0;

pub fn setPage(page: u64) void {
    const bit: u3 = @intCast(page % 8);
    const idx: usize = @intCast(page / 8);
    bitmap[idx] |= (@as(u8, 1) << bit);
}

pub fn clearPage(page: u64) void {
    const bit: u3 = @intCast(page % 8);
    const idx: usize = @intCast(page / 8);
    bitmap[idx] &= ~(@as(u8, 1) << bit);
}

pub fn pageUsed(page: u64) bool {
    const bit: u3 = @intCast(page % 8);
    const idx: usize = @intCast(page / 8);
    return (bitmap[idx] & (@as(u8, 1) << bit)) != 0;
}

pub fn pmmInit() void {
    stdio.kprint("[PMM] Initializing Physical Memory Manager...\n");

    for (&bitmap) |*byte| {
        byte.* = 0xFF;
    }

    total_pages = 0;
    free_pages = 0;

    stdio.kprint("[PMM] Physical Memory Manager initialized.\n");
}

pub fn pmmAddRegion(base: u64, length: u64) void {
    const start = (base + PMM_PAGE_SIZE - 1) & ~(PMM_PAGE_SIZE - 1);
    const end = (base + length) & ~(PMM_PAGE_SIZE - 1);

    if (end <= start) {
        stdio.kprint("[PMM] Skipping region (end <= start)\n");
        return;
    }

    var addr: u64 = start;
    while (addr < end) : (addr += PMM_PAGE_SIZE) {
        const page = addr / PMM_PAGE_SIZE;

        if (page >= MAX_PAGES) {
            break;
        }

        if (pageUsed(page)) {
            clearPage(page);
            total_pages += 1;
            free_pages += 1;
        }
    }
}

pub fn pmmReserveRegion(base: u64, length: u64) void {
    const start = base & ~(PMM_PAGE_SIZE - 1);
    const end = (base + length + PMM_PAGE_SIZE - 1) & ~(PMM_PAGE_SIZE - 1);

    if (end <= start) return;

    var addr: u64 = start;
    while (addr < end) : (addr += PMM_PAGE_SIZE) {
        const page = addr / PMM_PAGE_SIZE;
        if (page >= MAX_PAGES) break;

        if (!pageUsed(page)) {
            setPage(page);
            free_pages -= 1;
        }
    }
}

pub fn pmmAllocPage() ?u64 {
    var page: u64 = 1;
    while (page < MAX_PAGES) : (page += 1) {
        if (!pageUsed(page)) {
            setPage(page);
            free_pages -= 1;
            return page * PMM_PAGE_SIZE;
        }
    }
    return null;
}

pub fn pmmFreePage(addr: u64) void {
    if (addr % PMM_PAGE_SIZE != 0) {
        stdio.kprint("[PMM] Error: Address is not page-aligned\n");
        return;
    }

    const page = addr / PMM_PAGE_SIZE;
    if (page >= MAX_PAGES) return;

    if (pageUsed(page)) {
        clearPage(page);
        free_pages += 1;
    }
}

pub fn pmmGetTotalPages() u64 {
    return total_pages;
}

pub fn pmmGetFreePages() u64 {
    return free_pages;
}

pub fn pmmAllocPageLow() ?u64 {
    var page: u64 = 1;
    while (page < 2048) : (page += 1) {
        if (!pageUsed(page)) {
            setPage(page);
            free_pages -= 1;
            return page * PMM_PAGE_SIZE;
        }
    }
    return null;
}
