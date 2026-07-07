; Atlas64 BIOS stage-1 boot sector
; Loads the 64-bit kernel image at 0x10000, enables long mode, then jumps to it.

[bits 16]
[org 0x7C00]

KERNEL_SEGMENT equ 0x1000
KERNEL_OFFSET  equ 0x0000
KERNEL_SECTORS equ 128

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    mov [boot_drive], dl

    ; Enable A20 so memory above 1 MiB can be addressed safely.
    in al, 0x92
    or al, 0x02
    out 0x92, al

    ; Read kernel.bin from sector 2 onward into physical address 0x10000.
    mov ax, KERNEL_SEGMENT
    mov es, ax
    mov bx, KERNEL_OFFSET

    mov ah, 0x02
    mov al, KERNEL_SECTORS
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    ; Load 64-bit-capable GDT and enter protected mode.
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
disk_error_message db "Disk read error", 0

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

    ; Build identity-mapped page tables at 0x1000, 0x2000, and 0x3000.
    ; This maps the first 2 MiB, enough for this early kernel.
    mov edi, 0x1000
    xor eax, eax
    mov ecx, 1536
    rep stosd

    ; PML4[0] -> PDPT
    mov dword [0x1000], 0x2003

    ; PDPT[0] -> page directory
    mov dword [0x2000], 0x3003

    ; PD[0] -> first 2 MiB page, present + writable + huge page
    mov dword [0x3000], 0x0083

    ; Enable PAE.
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; Load PML4.
    mov eax, 0x1000
    mov cr3, eax

    ; Enable long mode in EFER.
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; Enable paging and protected mode.
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

times 510 - ($ - $$) db 0
dw 0xAA55
