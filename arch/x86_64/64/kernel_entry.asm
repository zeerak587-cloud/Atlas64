; TinyTextOS x86_64 long-mode entry point

[bits 64]

global _start
extern kernel_main

_start:
    call kernel_main

hang:
    jmp hang
