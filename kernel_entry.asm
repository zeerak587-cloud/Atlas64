; Atlas32 x86 32-bit protected-mode entry point

[bits 32]

global _start
extern kernel_main

_start:
    call kernel_main

hang:
    jmp hang
