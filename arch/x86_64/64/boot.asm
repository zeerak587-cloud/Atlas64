; TinyTextOS BIOS bootloader for x86_64 long mode

[bits 16]
[org 0x7C00]

KERNEL_OFFSET equ 0x1000
KERNEL_SECTORS equ 16
PML4_TABLE equ 0x7000
PDPT_TABLE equ 0x8000
PD_TABLE equ 0x9000

start:
    cli

    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    mov [BOOT_DRIVE], dl

    call enable_a20
    call load_kernel

    cli
    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp CODE32_SEG:init_pm

enable_a20:
    in al, 0x92
    or al, 2
    out 0x92, al
    ret

load_kernel:
    mov bx, KERNEL_OFFSET
    mov ah, 0x02
    mov al, KERNEL_SECTORS
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [BOOT_DRIVE]
    int 0x13
    jc disk_error
    ret

disk_error:
    mov si, error_msg

.print:
    lodsb
    or al, al
    jz $

    mov ah, 0x0E
    int 0x10
    jmp .print

BOOT_DRIVE db 0
error_msg db 'Disk error',0

gdt_start:
gdt_null:
    dq 0
gdt_code32:
    dw 0xFFFF
    dw 0
    db 0
    db 10011010b
    db 11001111b
    db 0
gdt_code64:
    dw 0
    dw 0
    db 0
    db 10011010b
    db 10100000b
    db 0
gdt_data:
    dw 0xFFFF
    dw 0
    db 0
    db 10010010b
    db 11001111b
    db 0
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE32_SEG equ gdt_code32 - gdt_start
CODE64_SEG equ gdt_code64 - gdt_start
DATA_SEG equ gdt_data - gdt_start

[bits 32]

init_pm:
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov edi, PML4_TABLE
    xor eax, eax
    mov ecx, 3072
    rep stosd

    mov dword [PML4_TABLE], PDPT_TABLE | 0x03
    mov dword [PML4_TABLE + 4], 0
    mov dword [PDPT_TABLE], PD_TABLE | 0x03
    mov dword [PDPT_TABLE + 4], 0
    mov dword [PD_TABLE], 0x00000083
    mov dword [PD_TABLE + 4], 0

    mov eax, PML4_TABLE
    mov cr3, eax

    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    jmp CODE64_SEG:init_lm

[bits 64]

init_lm:
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov rbp, 0x90000
    mov rsp, rbp

    jmp KERNEL_OFFSET

hang:
    jmp hang

times 510-($-$$) db 0
dw 0xAA55
