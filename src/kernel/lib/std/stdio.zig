const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;
const DEFAULT_COLOR = 0x07;
const BACKSPACE = 0x08;

var vga_buffer: [*]volatile u16 = @ptrFromInt(0xB8000);

var cursor_x: usize = 0;
var cursor_y: usize = 0;

fn vgaEntry(c: u8, color: u8) u16 {
    return (@as(u16, color) << 8) | @as(u16, c);
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
}

//pub fn putChar(c: u8) void {
//  vga_buffer[0] = vgaEntry(c, DEFAULT_COLOR);
//}
