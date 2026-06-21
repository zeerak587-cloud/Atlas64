# ARM Port

This directory contains the ARM 32-bit source port for QEMU `virt`.

ARM does not use the BIOS boot flow from the x86 build. This port uses a small
startup file, a linker script, and PL011 UART output at `0x09000000`.

It is intentionally minimal for now: UART output works, but the VGA shell,
keyboard input, PIT timer, and PC speaker are x86-only.
