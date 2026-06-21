/* TinyTextOS x86_64 kernel linker script */

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
