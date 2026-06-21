# ARM64 Port

This directory contains the ARM64 source port for QEMU `virt`.

ARM64 does not use the BIOS floppy image path used by x86. This port uses a
small startup file, a linker script, and PL011 UART output at `0x09000000`.

It is intentionally minimal for now: UART output works, but the VGA shell,
keyboard input, PIT timer, and PC speaker are x86-only.
