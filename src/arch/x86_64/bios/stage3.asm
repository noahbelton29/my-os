;; Copyright (C) 2026 noahbelton29
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, using version 3 of the License.

[BITS 16]
[ORG 0x8000]

start:
    mov [boot_drive], dl               ; save boot drive number BIOS gave us

    xor ax, ax                         ; ax = 0
    mov ds, ax                         ; data segment = 0
    mov es, ax                         ; extra segment = 0

    ;                                  ; use int 0x13 extended read
    mov ah, 0x42                       ; extended read function
    mov dl, [boot_drive]               ; drive number
    mov si, dap                        ; DS:SI = disk address packet
    int 0x13                           ; call BIOS disk interrupt
    jc .disk_error                     ; jump if carry flag set (read failed)

    cli                                ; disable interrupts before entering protected mode
    lgdt [gdt_descriptor]              ; load the global descriptor table

    mov eax, cr0                       ; read control register 0
    or eax, 0x1                        ; set protected mode bit
    mov cr0, eax                       ; write back to CR0

    jmp 0x08:protected_mode            ; far jump to flush pipeline and load CS with code segment

.disk_error:
    mov si, msg_disk_error             ; SI = pointer to error message
.print:
    lodsb                              ; load byte at DS:SI into AL, increment SI
    test al, al                        ; check for null terminator
    jz .hang                           ; if yes, stop printing
    mov ah, 0x0E                       ; BIOS teletype function
    int 0x10                           ; call BIOS video interrupt
    jmp .print
.hang:
    hlt                                ; halt the CPU
    jmp .hang                          ; loop in case of NMI wakeup

[BITS 32]
protected_mode:
    mov ax, 0x10                       ; data segment selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000                   ; temporary stack

    ;                                  ; clear page table area: 0x1000 - 0x5000
    mov edi, 0x1000                    ; start of page tables
    mov ecx, 0x4000 / 4                ; 16KB / 4 bytes per dword
    xor eax, eax                       ; fill with zeros
    rep stosd                          ; clear it

    ;                                  ; PML4 at 0x1000: one entry pointing to PDPT at 0x2000
    mov dword [0x1000], 0x2003         ; present + writable, address 0x2000
    mov dword [0x1004], 0              ; high 32 bits = 0

    ;                                  ; PDPT at 0x2000: one entry pointing to PD at 0x3000
    mov dword [0x2000], 0x3003         ; present + writable, address 0x3000
    mov dword [0x2004], 0              ; high 32 bits = 0

    ;                                  ; PD at 0x3000: one entry pointing to PT at 0x4000
    mov dword [0x3000], 0x4003         ; present + writable, address 0x4000
    mov dword [0x3004], 0              ; high 32 bits = 0

    ;                                  ; PT at 0x4000: 512 entries mapping first 2MB identity
    mov edi, 0x4000                    ; start of page table
    mov eax, 0x0003                    ; first page: address 0, present + writable
    mov ecx, 512                       ; 512 pages
.fill_pt:
    mov dword [edi], eax               ; write low 32 bits of entry
    mov dword [edi + 4], 0             ; write high 32 bits = 0
    add eax, 0x1000                    ; next page 4KB further
    add edi, 8                         ; next entry 8 bytes each
    loop .fill_pt

    ;                                  ; load PML4 address into CR3
    mov eax, 0x1000                    ; PML4 is at 0x1000
    mov cr3, eax

    ;                                  ; enable PAE in CR4
    mov eax, cr4
    or eax, (1 << 5)                   ; set PAE bit: bit 5
    mov cr4, eax

    ;                                  ; enable long mode in EFER MSR
    mov ecx, 0xC0000080                ; EFER MSR number
    rdmsr                              ; read into EDX:EAX
    or eax, (1 << 8)                   ; set LME bit long mode enable, bit 8
    wrmsr                              ; write back

    ;                                  ; enable paging in CR0, activates long mode
    mov eax, cr0
    or eax, (1 << 31)                  ; set PG bit: bit 31
    mov cr0, eax

    ;                                  ; far jump into 64-bit code segment to flush pipeline
    jmp 0x18:long_mode                 ; 0x18 = third GDT entry: 64-bit code segment

[BITS 64]
long_mode:
    mov ax, 0x20                       ; 64-bit data segment selector: fourth GDT entry
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov rsp, 0x90000                   ; set 64-bit stack pointer

    mov rax, 0x9000
    call rax

.hang:
    cli                                ; disable interrupts
    hlt                                ; halt the CPU
    jmp .hang                          ; loop in case of NMI wakeup

; Disk Address Packet for int 0x13 ah=0x42
dap:
    db 0x10                            ; size of DAP = 16 bytes
    db 0x00                            ; reserved
    dw 0x10                            ; number of sectors to read (16)
    dw 0x9000                          ; offset to load into
    dw 0x0000                          ; segment to load into 0x0000:0x9000
    dq 0x0000000000000005              ; LBA start sector: sector 5 = kernel, 0-indexed

boot_drive      db 0
msg_disk_error  db "Kernel load failed!", 0

gdt_start:
    dq 0x0000000000000000              ; null descriptor
    dq 0x00CF9A000000FFFF              ; 32-bit code segment (selector 0x08)
    dq 0x00CF92000000FFFF              ; 32-bit data segment (selector 0x10)
    dq 0x00AF9A000000FFFF              ; 64-bit code segment (selector 0x18), L bit set
    dq 0x00AF92000000FFFF              ; 64-bit data segment (selector 0x20)
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1         ; GDT size in bytes minus 1
    dd gdt_start                       ; linear address of GDT

times 1024 - ($ - $$) db 0