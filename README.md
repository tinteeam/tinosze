# TinosZE

TinosZE is a small experimental operating-system kernel written in Zig for
x86_64 PCs. It boots through GRUB using the Multiboot2 protocol, switches from
the 32-bit GRUB entry environment into x86_64 long mode, initializes a physical
memory manager, and provides VGA text output, serial output, keyboard input, and
a small command shell.

## Current status

- Target: `x86_64-freestanding-none`
- Boot protocol: GRUB Multiboot2
- Kernel format: 64-bit ELF
- Memory management: physical page bitmap with a 64 GiB tracking limit
- Console: VGA text mode at `80x25`
- Serial port: COM1
- Available shell commands: `help`, `ver`, `meminfo`, and `hlt`

This is an experimental kernel, not a general-purpose operating system. It is
intended to be built and run in an emulator or virtual machine.

## Requirements

Install the following tools on a Linux system:

- Zig `0.16.0`
- GNU `ld` with x86_64 ELF support
- GRUB utilities:
  - `grub-file`
  - `grub-mkrescue`
- `xorriso`, used by `grub-mkrescue`
- QEMU x86_64, for running the ISO

The required Zig version is recorded in [.zigversion](./.zigversion).

On Debian or Ubuntu, the host packages are typically:

```sh
sudo apt install build-essential binutils grub-pc-bin grub-common xorriso qemu-system-x86
```

Install Zig separately if it is not already available as `zig` in `PATH`.

## Build from source

Clone the repository and enter its root directory:

```sh
git clone https://github.com/tinteeam/tinosze.git
cd tinosze
```

Build the kernel object, link the x86_64 ELF kernel, create the GRUB directory
tree, validate the Multiboot2 header, and create the bootable ISO:

```sh
./build.sh
```

The script performs these steps:

1. Runs `zig build`.
2. Links `zig-out/bin/kernel.o` with [linker.ld](./linker.ld) as
   `zig-out/bin/kernel.elf`.
3. Copies the kernel and [GRUB configuration](./Bootloader/grub.cfg) into
   `iso_root/`.
4. Checks the kernel with `grub-file --is-x86-multiboot2`.
5. Writes `tinosze.iso`.

The generated files are build artifacts and are not required to edit the
source. To compile only the kernel object without creating an ISO, run:

```sh
zig build
```

## Run in QEMU

### Graphical VGA console

Build first, then start QEMU with the generated ISO:

```sh
./build.sh
qemu-system-x86_64 -cdrom tinosze.iso
```

The kernel uses the VGA text buffer and the emulated keyboard. Once it starts,
type a command at the `>` prompt.

### Serial output

To run without a graphical display and send COM1 output to the terminal:

```sh
qemu-system-x86_64 \
  -cdrom tinosze.iso \
  -display none \
  -serial stdio \
  -no-reboot \
  -no-shutdown
```

This is useful for observing boot messages and kernel diagnostics. The
interactive shell is primarily intended for the VGA console mode.

## Shell commands

| Command | Description |
| --- | --- |
| `help` | List available commands |
| `ver` | Show TinosZE, Zig, driver, and memory-manager versions |
| `meminfo` | Show total, used, and free physical memory |
| `hlt` | Disable interrupts and halt the CPU |

## Clean generated files

Remove the generated ISO, GRUB staging directory, and Zig cache:

```sh
./cleanup.sh
```

The cleanup script removes:

- `iso_root/`
- `.zig-cache/`
- `.zig-out/` if present
- `tinosze.iso`

The normal Zig output directory is `zig-out/`; remove it separately if you
want a completely clean working tree:

```sh
rm -rf zig-out
```

## Source layout

```text
Bootloader/grub.cfg       GRUB menu and Multiboot2 kernel entry
build.zig                 Zig build definition and x86_64 target
build.sh                  Compile, link, validate, and ISO creation script
cleanup.sh                Build-artifact cleanup script
linker.ld                 Kernel ELF layout and fixed boot GDT placement
src/kernel/boot.S         32-bit Multiboot2 to x86_64 long-mode bootstrap
src/kernel/main.zig       Multiboot header and kernel entry point
src/kernel/SysInit.zig    Multiboot memory-map parsing and memory setup
src/kernel/mm/pmm.zig     Physical page bitmap allocator
src/kernel/mm/vmm.zig     Virtual-memory module
src/kernel/console/       VGA console, I/O ports, and shell interaction
src/kernel/drivers/       Keyboard driver
src/kernel/serial.zig     COM1 serial driver
src/kernel/commands/      Kernel shell commands
```

## Boot flow

GRUB enters the kernel through the Multiboot2 entry point in
[boot.S](./src/kernel/boot.S). The bootstrap:

1. Saves the Multiboot magic value and information pointer.
2. Builds identity-mapped page tables using 2 MiB pages.
3. Enables PAE, EFER.LME, and paging.
4. Loads the boot GDT and performs the far jump into 64-bit code.
5. Initializes the x86_64 stack and calls `kernel_main`.

The Multiboot2 header fields remain 32-bit because that is required by the
Multiboot2 specification. Runtime addresses, page-management state, and
pointer-sized values use 64-bit-capable types where appropriate.

## Troubleshooting

### `zig: command not found` or a version mismatch

Install Zig `0.16.0` and ensure the `zig` executable is available in `PATH`:

```sh
zig version
```

### `grub-mkrescue: command not found`

Install GRUB utilities and `xorriso`. On Debian or Ubuntu:

```sh
sudo apt install grub-pc-bin grub-common xorriso
```

### QEMU immediately resets

Rebuild the ISO and validate the generated kernel before running it:

```sh
./build.sh
grub-file --is-x86-multiboot2 zig-out/bin/kernel.elf
file zig-out/bin/kernel.elf
```

The final `file` output should identify the kernel as an `ELF 64-bit`
`x86-64` executable.
