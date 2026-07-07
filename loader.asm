; Atlas64 stage-2 loader
; Loaded by boot.asm at physical address 0x8000.

[bits 16]
[org 0x8000]

KERNEL_SEGMENT equ 0x1000
KERNEL_OFFSET  equ 0x0000
KERNEL_SECTORS equ 127

LOADER_SECTORS equ 16

start:
    cli

    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; boot.asm stored the BIOS boot drive here before jumping to us.
    mov dl, [boot_drive]

    ; Load kernel.bin after the loader.
    ; Disk layout:
    ; sector 1  = boot.bin
    ; sectors 2-17 = loader.bin (16 sectors)
    ; sector 18 onward = kernel.bin
    mov ax, KERNEL_SEGMENT
    mov es, ax
    xor bx, bx

    mov ah, 0x02
    mov al, KERNEL_SECTORS
    mov ch, 0
    mov cl, 18
    mov dh, 0
    int 0x13
    jc disk_error

    ; Enable A20.
    in al, 0x92
    or al, 0x02
    out 0x92, al

    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp CODE_SEG:protected_mode

disk_error:
    mov si, disk_error_message
.print:
    lodsb
    test al, al
    jz $
    mov ah, 0x0E
    int 0x10
    jmp .print

boot_drive db 0
disk_error_message db "Atlas64 kernel read error", 0

align 8
gdt_start:
    dq 0x0000000000000000
gdt_code:
    dq 0x00AF9A000000FFFF
gdt_data:
    dq 0x00AF92000000FFFF
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

[bits 32]
protected_mode:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov gs, ax

    mov esp, 0x90000

    ; Zero PML4, PDPT, and page directory:
    ; 0x1000 = PML4
    ; 0x2000 = PDPT
    ; 0x3000 = page directory
    mov edi, 0x1000
    xor eax, eax
    mov ecx, 3072
    rep stosd

    ; Identity-map the first 2 MiB with one 2 MiB page.
    mov dword [0x1000], 0x2003
    mov dword [0x2000], 0x3003
    mov dword [0x3000], 0x0083

    ; Enable PAE.
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; Point CR3 at PML4.
    mov eax, 0x1000
    mov cr3, eax

    ; Enable IA-32e long mode through EFER.
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; Enable paging.
    mov eax, cr0
    or eax, 0x80000001
    mov cr0, eax

    jmp CODE_SEG:long_mode

[bits 64]
long_mode:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov ss, ax

    mov rsp, 0x90000
    xor rbp, rbp

    jmp 0x10000
