;; Copyright (C) 2026 noahbelton29
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, using version 3 of the License.

[BITS 16]
[ORG 0x7C00]

start:
    cli                                ; disable interrupts
    xor ax, ax                         ; ax = 0
    mov ds, ax                         ; data segment = 0
    mov es, ax                         ; extra segment = 0
    mov ss, ax                         ; stack segment = 0
    mov sp, 0x7C00                     ; stack pointer
    sti                                ; re-enable interrupts

    mov [boot_drive], dl               ; save drive number BIOS gave us

    ;                                  ; load stage 2
    mov ah, 0x02                       ; read sectors function
    mov al, 0x02                       ; number of sectors to read
    mov ch, 0x00                       ; cylinder 0
    mov cl, 0x02                       ; sector 2
    mov dh, 0x00                       ; head 0
    mov dl, [boot_drive]               ; drive number from BIOS
    mov bx, 0x7E00                     ; load into memory at 0x7E00
    int 0x13
    jc disk_error                      ; jump if carry flag set

    mov dl, [boot_drive]               ; reload drive number
    mov [0x7C00 + 510], dl             ; store drive number for stage 2
    jmp 0x7E00                         ; jump to stage 2

; disk_error
; called if the disk read fails
disk_error:
    mov si, msg_error
    call print
    .hang:
        hlt
        jmp .hang

; print
; prints a message to the screen
; input: SI = pointer to null-terminated string
print:
    lodsb                              ; load byte at DS:SI into AL, then increment SI
    test al, al                        ; check for null terminator
    jz .done                           ; if yes, stop
    mov ah, 0x0E                       ; bios teletype function
    int 0x10                           ; call bios video interrupt
    jmp print
.done:
    ret

boot_drive db 0                        ; store drive number here

msg_error db "Disk error!", 0x0D, 0x0A, 0

times 510 - ($ - $$) db 0
dw 0xAA55