.section .text
.code32
.global _start
.extern gdt_descriptor
.extern kernel_main
.extern stack_bytes
.extern pml4_table
.extern pdpt_table
.extern pd_table
.type _start, @function

_start:
    cli
    movl %eax, %edi
    movl %ebx, %esi

    movl $pml4_table, %eax
    movl $pdpt_table, %ecx
    orl $3, %ecx
    movl %ecx, (%eax)
    movl $pd_table, %ecx
    orl $3, %ecx
    movl $pdpt_table, %eax
    movl %ecx, (%eax)

    xorl %ecx, %ecx
.fill_pd:
    movl %ecx, %eax
    shll $21, %eax
    orl $0x83, %eax
    movl $pd_table, %edx
    leal (%edx,%ecx,8), %edx
    movl %eax, (%edx)
    movl $0, 4(%edx)
    incl %ecx
    cmpl $512, %ecx
    jb .fill_pd

    movl $pml4_table, %eax
    movl %eax, %cr3
    movl %cr4, %eax
    orl $0x20, %eax
    movl %eax, %cr4

    movl $0xc0000080, %ecx
    rdmsr
    orl $0x100, %eax
    wrmsr

    movl %cr0, %eax
    orl $0x80000001, %eax
    movl %eax, %cr0

    lgdt 0x10f000
    ljmp $0x08, $.long_mode_start

.code64
.long_mode_start:
    movw $0x10, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %ss
    movq $stack_bytes + 16384, %rsp
    andq $-16, %rsp
    call kernel_main

.halt:
    cli
    hlt
    jmp .halt

.size _start, . - _start
.section .boot_gdt,"a"
.align 8
.global gdt_descriptor
gdt_descriptor:
    .word gdt_end - gdt - 1
    .quad gdt
gdt:
    .quad 0
    .quad 0x00af9a000000ffff
    .quad 0x00af92000000ffff
gdt_end:

.section .note.GNU-stack,"",@progbits
