
const pmm = @import("pmm.zig");
const stdio = @import("../lib/std/stdio.zig");

const PAGE_SIZE: u64 = 0x1000;
const PAGE_ENTRIES: usize = 512;
const PAGE_ADDRESS_MASK: u64 = 0x000F_FFFF_FFFF_F000;
const PAGE_FLAG_PRESENT: u64 = 0x001;
const PAGE_FLAG_WRITABLE: u64 = 0x002;
const PAGE_FLAG_HUGE: u64 = 0x080;
const PAGE_FLAG_MASK: u64 = 0xFFF;
const BOOTSTRAP_IDENTITY_LIMIT: u64 = 1024 * 1024 * 1024;
const LARGE_PAGE_SIZE: u64 = 2 * 1024 * 1024;

const PageTable = [PAGE_ENTRIES]u64;

var initial_pml4: PageTable align(4096) linksection(".data.boot") = [_]u64{0} ** PAGE_ENTRIES;

var initial_pdpt: PageTable align(4096) linksection(".data.boot") = [_]u64{0} ** PAGE_ENTRIES;

var initial_page_directory: PageTable align(4096) linksection(".data.boot") = undefined;

var paging_enabled: bool linksection(".data.boot") = false;

fn pageAlignedAddress(address: u64) bool {
    return (address & (PAGE_SIZE - 1)) == 0;
}

fn canonicalAddress(address: u64) bool {
    const upper = address >> 47;
    return upper == 0 or upper == 0x1FFFF;
}

fn zeroPage(page: *PageTable) void {
    @memset(page, 0);
}

fn physicalToBootstrapVirtual(address: u64) ?*PageTable {
    if (address >= BOOTSTRAP_IDENTITY_LIMIT or
        !pageAlignedAddress(address))
    {
        return null;
    }

    return @ptrFromInt(address);
}

fn entryTable(entry: u64) ?*PageTable {
    if ((entry & PAGE_FLAG_PRESENT) == 0 or
        (entry & PAGE_FLAG_HUGE) != 0)
    {
        return null;
    }

    return physicalToBootstrapVirtual(entry & PAGE_ADDRESS_MASK);
}

fn tableEntry(address: u64) u64 {
    return (address & PAGE_ADDRESS_MASK) |
        PAGE_FLAG_PRESENT |
        PAGE_FLAG_WRITABLE;
}

fn allocateTable() ?*PageTable {
    const address = pmm.pmmAllocPageLow() orelse return null;

    const table = physicalToBootstrapVirtual(address) orelse {
        pmm.pmmFreePage(address);
        return null;
    };

    zeroPage(table);
    return table;
}

fn nextTable(table: *PageTable, index: usize) ?*PageTable {
    const entry = table[index];

    if ((entry & PAGE_FLAG_PRESENT) != 0) {
        return entryTable(entry);
    }

    const next = allocateTable() orelse return null;
    table[index] = tableEntry(@intFromPtr(next));
    return next;
}

fn flushTlbPage(address: u64) void {
    asm volatile ("invlpg (%[addr])"
        :
        : [addr] "r" (address),
    );
}

fn reloadPageDirectory() void {
    const address = @intFromPtr(&initial_pml4);

    asm volatile ("mov %[addr], %%cr3"
        :
        : [addr] "r" (address),
    );
}

pub fn vmmInit() void {
    stdio.kprint("[VMM] Initializing x86_64 Virtual Memory Management...\n");
    pagingInit();
    stdio.kprint("[VMM] Initialized.\n");
}

pub fn pagingInit() void {
    if (paging_enabled) return;

    zeroPage(&initial_pml4);
    zeroPage(&initial_pdpt);
    zeroPage(&initial_page_directory);

    initial_pml4[0] = @intFromPtr(&initial_pdpt) | 0x003;
    initial_pdpt[0] = @intFromPtr(&initial_page_directory) | 0x003;

    for (0..PAGE_ENTRIES) |i| {
        initial_page_directory[i] = @as(u64, @intCast(i)) * LARGE_PAGE_SIZE |
            PAGE_FLAG_PRESENT |
            PAGE_FLAG_WRITABLE |
            PAGE_FLAG_HUGE;
    }

    reloadPageDirectory();
    paging_enabled = true;

    stdio.kprint("[PAGING] Installed 1 GiB identity map.\n");
}

pub fn mapPage(
    virtual_address: u64,
    physical_address: u64,
    flags: u64,
) void {
    if (!paging_enabled or
        !canonicalAddress(virtual_address) or
        !pageAlignedAddress(virtual_address) or
        !pageAlignedAddress(physical_address) or
        (physical_address & ~PAGE_ADDRESS_MASK) != 0 or
        (flags & ~PAGE_FLAG_MASK) != 0)
    {
        return;
    }

    const pml4_index: usize = @intCast((virtual_address >> 39) & 0x1FF);
    const pdpt_index: usize = @intCast((virtual_address >> 30) & 0x1FF);
    const pd_index: usize = @intCast((virtual_address >> 21) & 0x1FF);
    const pt_index: usize = @intCast((virtual_address >> 12) & 0x1FF);

    const pdpt = nextTable(&initial_pml4, pml4_index) orelse return;
    const pd = nextTable(pdpt, pdpt_index) orelse return;

    // Do not mistake a 2 MiB large-page mapping for a page-table pointer.
    if ((pd[pd_index] & PAGE_FLAG_HUGE) != 0) {
        return;
    }

    const pt = nextTable(pd, pd_index) orelse return;

    pt[pt_index] = (physical_address & PAGE_ADDRESS_MASK) |
        (flags & PAGE_FLAG_MASK) |
        PAGE_FLAG_PRESENT;

    flushTlbPage(virtual_address);
}

pub fn unmapPage(virtual_address: u64) void {
    if (!paging_enabled or
        !canonicalAddress(virtual_address) or
        !pageAlignedAddress(virtual_address))
    {
        return;
    }

    const pml4_index: usize = @intCast((virtual_address >> 39) & 0x1FF);
    const pdpt_index: usize = @intCast((virtual_address >> 30) & 0x1FF);
    const pd_index: usize = @intCast((virtual_address >> 21) & 0x1FF);
    const pt_index: usize = @intCast((virtual_address >> 12) & 0x1FF);

    const pdpt = entryTable(initial_pml4[pml4_index]) orelse return;
    const pd = entryTable(pdpt[pdpt_index]) orelse return;
    const pt = entryTable(pd[pd_index]) orelse return;

    pt[pt_index] = 0;
    flushTlbPage(virtual_address);
}

pub fn getPageTable(virtual_address: u64) ?*PageTable {
    if (!paging_enabled or !canonicalAddress(virtual_address)) {
        return null;
    }

    const pml4_index: usize = @intCast((virtual_address >> 39) & 0x1FF);
    const pdpt_index: usize = @intCast((virtual_address >> 30) & 0x1FF);
    const pd_index: usize = @intCast((virtual_address >> 21) & 0x1FF);

    const pdpt = entryTable(initial_pml4[pml4_index]) orelse return null;
    const pd = entryTable(pdpt[pdpt_index]) orelse return null;

    // Large pages have no corresponding 4 KiB PT.
    if ((pd[pd_index] & PAGE_FLAG_HUGE) != 0) return null;

    return entryTable(pd[pd_index]);
}

pub fn getAllPages(
    page_table: ?[*]u64,
    page_directory: ?[*]u64,
) void {
    const pt = page_table orelse return;
    const pd = page_directory orelse return;

    const pt_address = @intFromPtr(pt);
    const pd_address = @intFromPtr(pd);

    if (pt_address == pd_address or
        !pageAlignedAddress(pt_address) or
        !pageAlignedAddress(pd_address))
    {
        return;
    }

    for (0..PAGE_ENTRIES) |i| {
        pt[i] = @as(u64, @intCast(i)) * PAGE_SIZE |
            PAGE_FLAG_PRESENT |
            PAGE_FLAG_WRITABLE;
    }

    @memset(pd[0..PAGE_ENTRIES], 0);
    pd[0] = tableEntry(pt_address);
}

pub fn pageFaultHandler() noreturn {
    var fault_address: u64 = undefined;

    asm volatile ("mov %%cr2, %[addr]"
        : [addr] "=r" (fault_address),
    );

    stdio.kprint("[VMM] Page fault at address: ");
    stdio.printU64(fault_address);
    stdio.putChar('\n');

    asm volatile ("cli" ::: "memory");

    while (true) {
        asm volatile ("hlt");
    }
}
