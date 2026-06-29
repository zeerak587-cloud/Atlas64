/* Atlas32 x86 32-bit kernel linker script */

ENTRY(_start)

SECTIONS
{
    . = 0x1000;

    .text :
    {
        *(.text)
    }

    .rodata :
    {
        *(.rodata)
    }

    .data :
    {
        *(.data)
    }

    .bss :
    {
        *(.bss)
    }
}
