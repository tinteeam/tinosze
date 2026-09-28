OUTPUT_FORMAT("elf64-x86-64")
OUTPUT_ARCH(i386:x86-64)

ENTRY(_start)

/* FORCE the linker to merge structural headers into our high-memory segments */
PHDRS
{
    limine_requests PT_LOAD;
    text PT_LOAD;
    rodata PT_LOAD;
    data PT_LOAD;
}

SECTIONS
{
    /* Map everything starting in the higher half space */
    . = 0xffffffff80000000;

    .limine_requests : ALIGN(4K) {
        KEEP(*(.limine_requests))
    } :limine_requests

    .text : ALIGN(4K) {
        *(.text .text.*)
    } :text

    .rodata : ALIGN(4K) {
        *(.rodata .rodata.*)
    } :rodata

    .data : ALIGN(4K) {
        *(.data .data.*)
    } :data

    .bss : ALIGN(4K) {
        *(.bss .bss.*)
        *(COMMON)
    } :data

    /* Strictly discard low-half metadata clutter */
    /DISCARD/ : {
        *(.note .note.*)
        *(.interp)
        *(.comment)
        *(.eh_frame)
    }
}
