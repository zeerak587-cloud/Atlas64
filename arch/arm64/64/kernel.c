typedef unsigned int u32;

#define UART0_BASE 0x09000000u
#define UART_DR    0x00u
#define UART_FR    0x18u
#define UART_FR_TXFF (1u << 5)

static volatile u32* const uart0 = (volatile u32*)UART0_BASE;

static void uart_putc(char c)
{
    while (uart0[UART_FR / 4] & UART_FR_TXFF) {
    }

    uart0[UART_DR / 4] = (u32)c;
}

static void uart_print(const char* text)
{
    while (*text) {
        if (*text == '\n') {
            uart_putc('\r');
        }

        uart_putc(*text);
        text++;
    }
}

void kernel_main(void)
{
    uart_print("TinyTextOS ARM64 booted on QEMU virt.\n");
    uart_print("This port has UART output only for now.\n");

    for (;;) {
    }
}
