#ifndef TINYTEXTOS_ARCH_IO_H
#define TINYTEXTOS_ARCH_IO_H

#define ARCH_NAME "x86"
#define ARCH_BITS 32
#define ARCH_VGA_MEMORY ((u16*)0xB8000)

static inline void outb(u16 port, u8 value)
{
    asm volatile ("outb %0, %1" : : "a"(value), "Nd"(port));
}

static inline u8 inb(u16 port)
{
    u8 value;

    asm volatile ("inb %1, %0" : "=a"(value) : "Nd"(port));

    return value;
}

#endif
