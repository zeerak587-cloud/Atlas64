.section .text
.global _start

_start:
    ldr sp, =stack_top
    bl kernel_main

hang:
    b hang

.section .bss
.align 12
stack_bottom:
    .skip 16384
stack_top:
