#!/bin/bash
set -e

echo "[1/4] Compiling Zig-kernel..."
zig build

echo "[2/4] Linking kernel"
ld -T linker.ld -o ./zig-out/bin/kernel.elf ./zig-out/bin/kernel.o -m elf_i386

echo "[3/4] Building ISO-folder Structure..."
rm -rf iso_root tinos3c.iso
mkdir -p iso_root/boot/grub

cp ./zig-out/bin/kernel.elf ./iso_root/boot/kernel.elf
cp ./Bootloader/grub.cfg ./iso_root/boot/grub/grub.cfg

echo "[3/4] Creating Bootable GRUB ISO-image..."
grub-file --is-x86-multiboot2 ./iso_root/boot/kernel.elf
grub-mkrescue -o tinosze.iso iso_root
