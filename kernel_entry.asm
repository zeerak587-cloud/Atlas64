; Atlas64 x86-64 kernel entry point

[bits 64]

global _start
extern kernel_main

section .text
_start:
    cli
    cld

    mov rsp, 0x90000
    xor rbp, rbp

    call kernel_main

.hang:
    hlt
    jmp .hang
