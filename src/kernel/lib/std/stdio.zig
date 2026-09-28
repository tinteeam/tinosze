const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;
const DEFAULT_COLOR = 0x07;
const BACKSPACE = 0x08;

var vga_buffer: [*]volatile u16 = @ptrFromInt(0xB8000);

var cursor_x: u32 = 0;
var cursor_y: u32 = 0;

fn vgaEntry(c: u8, color: u8) u16 {
    return (@as(u16, color) << 8) | @as(u16, c);
}

pub fn inb(port: u16) u8 {
    var ret: u8 = undefined;

    asm volatile ("inb %[port], %[ret]"
        : [ret] "={al}" (ret),
        : [port] "{dx}" (port),
    );

    return ret;
}

pub fn outb(port: u16, val: u8) void {
    asm volatile ("outb %[val], %[port]"
        :
        : [val] "{al}" (val),
          [port] "{dx}" (port),
    );
}

pub fn ioWait() void {
    asm volatile ("outb %%al, $0x80"
        :
        : [val] "{al}" (@as(u8, 0)),
    );
}

pub fn putChar(c: u8) void {
    if (c == '\n') {
        cursor_x = 0;
        cursor_y += 1;
    } else if (c == BACKSPACE) {
        if (cursor_x > 0) {
            cursor_x -= 1;
            vga_buffer[cursor_y * VGA_WIDTH + cursor_x] = vgaEntry(' ', DEFAULT_COLOR);
        }
    } else {
        vga_buffer[cursor_y * VGA_WIDTH + cursor_x] = vgaEntry(c, DEFAULT_COLOR);
        cursor_x += 1;
        if (cursor_x >= VGA_WIDTH) {
            cursor_x = 0;
            cursor_y += 1;
        }
    }

    if (cursor_y >= VGA_HEIGHT) {
        scrollScreen();
        cursor_y = VGA_HEIGHT - 1;
    }

    updateCursor(cursor_x, cursor_y);
}

pub fn scrollScreen() void {
    var y: usize = 1;
    while (y < VGA_HEIGHT) : (y += 1) {
        var x: usize = 0;
        while (x < VGA_WIDTH) : (x += 1) {
            vga_buffer[(y - 1) * VGA_WIDTH + x] = vga_buffer[y * VGA_WIDTH + x];
        }
    }

    var x: usize = 0;
    while (x < VGA_WIDTH) : (x += 1) {
        vga_buffer[(VGA_HEIGHT - 1) * VGA_WIDTH + x] = vgaEntry(' ', 0x07);
    }

    if (cursor_y > 0) {
        cursor_y -= 1;
    }
}

pub fn updateCursor(x: usize, y: usize) void {
    const pos: u16 = @intCast(y * VGA_WIDTH + x);

    outb(0x3D4, 0x0F);
    outb(0x3D5, @intCast(pos & 0xFF));
    outb(0x3D4, 0x0E);
    outb(0x3D5, @intCast((pos >> 8) & 0xFF));
}

pub fn kprint(str: []const u8) void {
    for (str) |c| {
        putChar(c);
    }
    putChar('\n');
}
