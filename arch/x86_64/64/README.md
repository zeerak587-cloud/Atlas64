# x86_64 Port

This directory contains the x86_64 source port.

TinyTextOS enters long mode from the BIOS boot sector, identity maps the first
2 MiB, then jumps to the 64-bit kernel entry at `0x1000`.

This keeps the current VGA text, keyboard port I/O, PIT, and PC-speaker code
usable while the rest of the OS is made more portable.
