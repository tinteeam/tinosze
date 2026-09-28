const std = @import("std");

// --- NATIVE ZIG LIMINE PROTOCOL DEFINITIONS ---
// Limine identification tags
const LIMINE_COMMON_MAGIC: [4]u64 = .{ 0xc7b1dd30fa322e2e, 0x10a82747b1dd322e, 0x8cc466a0da217585, 0xbcab24c678a30d22 };

// Framebuffer Request ID: limine_common_magic + [0x671d432c52244c9d, 0x541251df3b6658ae]
pub const LIMINE_FRAMEBUFFER_REQUEST: [4]u64 = .{ LIMINE_COMMON_MAGIC[0], LIMINE_COMMON_MAGIC[1], 0x671d432c52244c9d, 0x541251df3b6658ae };

pub const LimineFramebuffer = extern struct {
    address: ?[*]u32,
    width: u64,
    height: u64,
    pitch: u64,
    bpp: u16,
    memory_model: u8,
    red_mask_size: u8,
    red_mask_shift: u8,
    green_mask_size: u8,
    green_mask_shift: u8,
    blue_mask_size: u8,
    blue_mask_shift: u8,
    unused: [7]u8,
};

pub const LimineFramebufferResponse = extern struct {
    revision: u64,
    framebuffer_count: u64,
    framebuffers: [*]const *LimineFramebuffer,
};

pub const LimineFramebufferRequest = extern struct {
    id: [4]u64,
    revision: u64,
    response: ?*LimineFramebufferResponse,
};
// --- END OF PROTOCOL DEFINITIONS ---

// Request a graphical framebuffer from Limine using our native struct
pub export var framebuffer_request: LimineFramebufferRequest = .{
    .id = LIMINE_FRAMEBUFFER_REQUEST,
    .revision = 0,
    .response = null,
};

// Target entry point signature using lowercase calling convention (.c)
export fn _start() callconv(.c) noreturn {
    if (framebuffer_request.response) |response| {
        if (response.framebuffer_count > 0) {
            // Get the pointer to the first framebuffer
            const fb = response.framebuffers[0];
            if (fb.address) |fb_address| {

                // Render our red calibration box (150x150 pixels)
                var y: u32 = 0;
                while (y < 150) : (y += 1) {
                    var x: u32 = 0;
                    while (x < 150) : (x += 1) {
                        const stride = fb.pitch / 4;
                        const index = (y * stride) + x;
                        fb_address[index] = 0x00FF0000; // Solid Red
                    }
                }
            }
        }
    }

    while (true) {
        asm volatile ("hlt");
    }
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    _ = msg;
    _ = error_return_trace;
    _ = ret_addr;
    while (true) {
        asm volatile ("hlt");
    }
}
