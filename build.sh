#!/bin/bash
set -e

echo "[1/4] Compiling Zig-kernel (Zig 0.17.0)..."
zig build

echo "[2/4] Creating a empty 64MB disk image..."
rm -f tinosze.img
dd if=/dev/zero of=tinosze.img bs=1M count=64

echo "[3/4] Creating MBR-partition table and initializing FAT32..."

printf "label: dos\nlabel-id: 0x12345678\ndevice: tinosze.img\nunit: sectors\n\ntinosze.img1 : start=2048, type=0c, bootable\n" | sfdisk tinosze.img

mformat -i tinosze.img@@1M -F

mmd -i tinosze.img@@1M ::/boot

mcopy -i tinosze.img@@1M ./zig-out/bin/kernel.elf ::/boot/kernel.elf
mcopy -i tinosze.img@@1M ./Bootloader/limine.conf ::/limine.conf


mcopy -i tinosze.img@@1M /usr/local/share/limine/limine-bios.sys ::/limine-bios.sys

echo "[4/4] Installing Limine-bootsectors to the disk image..."

limine bios-install tinosze.img