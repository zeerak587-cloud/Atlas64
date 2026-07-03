; Atlas32 BIOS bootloader for x86 32-bit

[bits 16]
[org 0x7C00]

KERNEL_OFFSET equ 0x1000
KERNEL_SECTORS equ 16

start:
    cli

    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    mov [BOOT_DRIVE], dl

    ; enable A20
    call enable_a20

    ; load kernel
    mov bx, KERNEL_OFFSET
    mov ah, 0x02
    mov al, KERNEL_SECTORS
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [BOOT_DRIVE]
    int 0x13

    jc disk_error

    cli
    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp CODE_SEG:init_pm

enable_a20:
    in al, 0x92
    or al, 2
    out 0x92, al
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

; ======================
; GDT
; ======================

gdt_start:

gdt_null:
    dq 0

gdt_code:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00

gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; ======================
; 32-bit mode
; ======================

[bits 32]

init_pm:
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebp, 0x90000
    mov esp, ebp

    jmp KERNEL_OFFSET

hang:
    jmp hang

times 510-($-$$) db 0
dw 0xAA55
