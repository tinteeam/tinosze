OUTPUT_FORMAT("elf64-x86-64")
OUTPUT_ARCH(i386:x86-64)

ENTRY(_start)

PHDRS
{
    text PT_LOAD FLAGS(5);       /* Read + Execute */
    rodata PT_LOAD FLAGS(4);     /* Read Only */
    data PT_LOAD FLAGS(6);       /* Read + Write */
}

SECTIONS
{
    /* Map everything explicitly into the higher half space */
    . = 0xffffffff80000000;

    .text : ALIGN(4K) {
        *(.text .text.*)
    } :text

    .rodata : ALIGN(4K) {
        *(.rodata .rodata.*)
    } :rodata

    .data : ALIGN(4K) {
        *(.data .data.*)
        *(.limine_requests)
    } :data

    .bss : ALIGN(4K) {
        *(.bss .bss.*)
        *(COMMON)
    } :data

    /* Throw away all automatic low-memory notes and frame records */
    /DISCARD/ : {
        *(.note .note.*)
        *(.interp)
        *(.comment)
        *(.eh_frame)
        *(.eh_frame_hdr)
    }
}
