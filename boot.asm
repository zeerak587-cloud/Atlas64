; Atlas64 stage-1 BIOS boot sector
; Disk layout:
;   sector 1       boot.bin
;   sectors 2-17   loader.bin (16 sectors)
;   sector 18+     kernel.bin

[bits 16]
[org 0x7C00]

LOADER_SEGMENT equ 0x0800
LOADER_SECTORS equ 16

start:
    cli

    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Keep the BIOS drive number for loader.asm.
    mov [0x0500], dl

    ; Read loader.bin: 16 sectors beginning at disk sector 2.
    mov ax, LOADER_SEGMENT
    mov es, ax
    xor bx, bx

    mov ah, 0x02
    mov al, LOADER_SECTORS
    mov ch, 0
    mov cl, 2
    mov dh, 0
    ; DL is still the BIOS boot drive.
    int 0x13
    jc disk_error

    jmp LOADER_SEGMENT:0x0000

disk_error:
    mov si, error_message
.print:
    lodsb
    test al, al
    jz .hang
    mov ah, 0x0E
    int 0x10
    jmp .print

.hang:
    cli
    hlt
    jmp .hang

error_message db "Atlas64 loader read error", 0

times 510 - ($ - $$) db 0
dw 0xAA55
