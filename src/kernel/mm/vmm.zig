pub const PAGE_SIZE: u64 = 0x1000;
pub const PAGE_ENTRIES: u64 = 512;
pub const PAGE_ADDRESS_MASK: u64 = 0xFFFFFFFFFFFFF000;
pub const PAGE_FLAGS_MASK: u64 = 0xFFF;
pub const PAGE_FLAGS_PRESENT: u64 = 0x001;
pub const PAGE_FLAGS_WRITABLE: u64 = 0x002;
pub const BOOTSTRAP_IDENTITY_LIMIT: u64 = 1024 * 1024 * 1024;

var initial_pml4: [PAGE_ENTRIES]u64 align(PAGE_SIZE) linksection(".data.boot") = undefined;
var initial_pdpt: [PAGE_ENTRIES]u64 align(PAGE_SIZE) linksection(".data.boot") = undefined;
var initial_pd: [PAGE_ENTRIES]u64 align(PAGE_SIZE) linksection(".data.boot") = undefined;
var initial_pt: [PAGE_ENTRIES]u64 align(PAGE_SIZE) linksection(".data.boot") = undefined;

var paging_enabled: usize linksection(".data.boot") = false;
